#!/usr/bin/env python3
"""
IAC Scan Aggregator - Runs multiple scans and generates a unified HTML report
"""

import os
import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any

class IACScanner:
    def __init__(self, workspace_root: str, output_dir: str = "scan-reports"):
        self.workspace_root = Path(workspace_root)
        self.output_dir = self.workspace_root / output_dir
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.reports = {}
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
    def run_terraform_validate(self) -> Dict[str, Any]:
        """Run Terraform validate on all modules"""
        print("\n Running Terraform validate...")
        results = {
            "tool": "Terraform Validate",
            "status": "success",
            "issues": [],
            "timestamp": datetime.now().isoformat()
        }
        
        terraform_dirs = [
            self.workspace_root / "terraform-bootstrap",
            self.workspace_root / "terraform-infra"
        ]
        
        for tf_dir in terraform_dirs:
            if not tf_dir.exists():
                continue
                
            try:
                # Initialize if needed
                subprocess.run(
                    ["terraform", "init", "-upgrade"],
                    cwd=tf_dir,
                    capture_output=True,
                    timeout=60
                )
                
                # Run validate
                result = subprocess.run(
                    ["terraform", "validate", "-json"],
                    cwd=tf_dir,
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                
                if result.returncode != 0:
                    results["status"] = "failed"
                    results["issues"].append({
                        "file": str(tf_dir.relative_to(self.workspace_root)),
                        "error": result.stderr,
                        "severity": "error"
                    })
                else:
                    try:
                        output = json.loads(result.stdout)
                        if "diagnostics" in output:
                            for diag in output["diagnostics"]:
                                results["issues"].append({
                                    "file": str(tf_dir.relative_to(self.workspace_root)),
                                    "issue": diag.get("summary", ""),
                                    "detail": diag.get("detail", ""),
                                    "severity": diag.get("severity", "warning")
                                })
                    except json.JSONDecodeError:
                        pass
                        
            except subprocess.TimeoutExpired:
                results["issues"].append({
                    "file": str(tf_dir.relative_to(self.workspace_root)),
                    "error": "Command timeout",
                    "severity": "warning"
                })
            except Exception as e:
                results["issues"].append({
                    "file": str(tf_dir.relative_to(self.workspace_root)),
                    "error": str(e),
                    "severity": "warning"
                })
        
        print(f"✓ Terraform validate completed with {len(results['issues'])} issues found")
        return results
    
    def run_opa_conftest(self) -> Dict[str, Any]:
        """Run OPA/Conftest policy checks"""
        print("\n Running OPA/Conftest policy checks...")
        results = {
            "tool": "OPA/Conftest",
            "status": "success",
            "issues": [],
            "timestamp": datetime.now().isoformat()
        }
        
        terraform_dirs = [
            self.workspace_root / "terraform-bootstrap",
            self.workspace_root / "terraform-infra"
        ]
        
        for tf_dir in terraform_dirs:
            if not tf_dir.exists():
                continue
                
            try:
                # Generate plan JSON
                plan_file = self.output_dir / f"tfplan_{tf_dir.name}.json"
                
                subprocess.run(
                    ["terraform", "plan", "-json", f"-out={plan_file}.tfplan"],
                    cwd=tf_dir,
                    capture_output=True,
                    timeout=120
                )
                
                # Run conftest
                result = subprocess.run(
                    ["conftest", "test", "-p", str(self.workspace_root / "policies"), 
                     "-o", "json", str(plan_file.with_suffix(".tfplan"))],
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                
                if result.stdout:
                    try:
                        output = json.loads(result.stdout)
                        if isinstance(output, list):
                            for test in output:
                                if test.get("failures"):
                                    results["status"] = "failed"
                                    for failure in test["failures"]:
                                        results["issues"].append({
                                            "file": test.get("filename", str(tf_dir)),
                                            "issue": failure.get("message", "Policy violation"),
                                            "severity": "error"
                                        })
                    except json.JSONDecodeError:
                        pass
                        
            except subprocess.TimeoutExpired:
                results["issues"].append({
                    "file": str(tf_dir.relative_to(self.workspace_root)),
                    "error": "Conftest timeout",
                    "severity": "warning"
                })
            except FileNotFoundError:
                print("Conftest not installed, skipping OPA checks")
                return {"tool": "OPA/Conftest", "status": "skipped", "issues": [], "timestamp": datetime.now().isoformat()}
            except Exception as e:
                results["issues"].append({
                    "file": str(tf_dir.relative_to(self.workspace_root)),
                    "error": str(e),
                    "severity": "warning"
                })
        
        print(f"✓ OPA/Conftest completed with {len(results['issues'])} issues found")
        return results
    
    def run_tflint(self) -> Dict[str, Any]:
        """Run TFLint for Terraform linting"""
        print("\n Running TFLint...")
        results = {
            "tool": "TFLint",
            "status": "success",
            "issues": [],
            "timestamp": datetime.now().isoformat()
        }
        
        terraform_dirs = [
            self.workspace_root / "terraform-bootstrap",
            self.workspace_root / "terraform-infra"
        ]
        
        for tf_dir in terraform_dirs:
            if not tf_dir.exists():
                continue
                
            try:
                result = subprocess.run(
                    ["tflint", "--format", "json", str(tf_dir)],
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                
                if result.stdout:
                    try:
                        output = json.loads(result.stdout)
                        
                        # Handle both new and old tflint JSON formats
                        issues_list = output.get("issues", output) if isinstance(output, dict) else output
                        
                        for issue in issues_list:
                            if isinstance(issue, dict):
                                results["issues"].append({
                                    "file": issue.get("range", {}).get("filename", str(tf_dir)),
                                    "line": issue.get("range", {}).get("start", {}).get("line", 0),
                                    "issue": issue.get("rule", {}).get("id", "unknown"),
                                    "message": issue.get("message", ""),
                                    "severity": issue.get("rule", {}).get("severity", "warning").lower()
                                })
                                
                                if issue.get("rule", {}).get("severity", "").upper() == "ERROR":
                                    results["status"] = "failed"
                                    
                    except json.JSONDecodeError:
                        pass
                        
            except subprocess.TimeoutExpired:
                results["issues"].append({
                    "file": str(tf_dir.relative_to(self.workspace_root)),
                    "error": "TFLint timeout",
                    "severity": "warning"
                })
            except FileNotFoundError:
                print("TFLint not installed, skipping linting")
                return {"tool": "TFLint", "status": "skipped", "issues": [], "timestamp": datetime.now().isoformat()}
            except Exception as e:
                results["issues"].append({
                    "file": str(tf_dir.relative_to(self.workspace_root)),
                    "error": str(e),
                    "severity": "warning"
                })
        
        print(f"✓ TFLint completed with {len(results['issues'])} issues found")
        return results
    
    def run_all_scans(self) -> List[Dict[str, Any]]:
        """Run all scans"""
        print(f"\n🚀 Starting IAC scans at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        scan_results = [
            self.run_terraform_validate(),
            self.run_opa_conftest(),
            self.run_tflint()
        ]
        
        return scan_results
    
    def generate_html_report(self, scan_results: List[Dict[str, Any]]) -> str:
        """Generate unified HTML report"""
        print("\n Generating HTML report...")
        
        # Calculate statistics
        total_issues = sum(len(r.get("issues", [])) for r in scan_results)
        errors = sum(1 for r in scan_results for i in r.get("issues", []) if i.get("severity") == "error")
        warnings = sum(1 for r in scan_results for i in r.get("issues", []) if i.get("severity") == "warning")
        
        # Generate HTML content
        html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IAC Scan Report</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }}
        
        .container {{
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            overflow: hidden;
        }}
        
        header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px 20px;
            text-align: center;
        }}
        
        header h1 {{
            font-size: 2.5em;
            margin-bottom: 10px;
        }}
        
        header p {{
            font-size: 1.1em;
            opacity: 0.9;
        }}
        
        .summary {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            padding: 30px 20px;
            background: #f8f9fa;
            border-bottom: 1px solid #e9ecef;
        }}
        
        .stat-card {{
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            text-align: center;
        }}
        
        .stat-card h3 {{
            color: #667eea;
            font-size: 2em;
            margin-bottom: 5px;
        }}
        
        .stat-card p {{
            color: #6c757d;
            font-size: 0.9em;
        }}
        
        .stat-card.error h3 {{
            color: #dc3545;
        }}
        
        .stat-card.warning h3 {{
            color: #ffc107;
        }}
        
        .stat-card.success h3 {{
            color: #28a745;
        }}
        
        .content {{
            padding: 30px 20px;
        }}
        
        .scan-section {{
            margin-bottom: 40px;
        }}
        
        .scan-section h2 {{
            color: #333;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
            display: flex;
            align-items: center;
            gap: 10px;
        }}
        
        .tool-status {{
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: bold;
            margin-left: auto;
        }}
        
        .status-success {{
            background: #d4edda;
            color: #155724;
        }}
        
        .status-failed {{
            background: #f8d7da;
            color: #721c24;
        }}
        
        .status-skipped {{
            background: #e2e3e5;
            color: #383d41;
        }}
        
        .issues-list {{
            list-style: none;
        }}
        
        .issue-item {{
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 15px;
            margin-bottom: 10px;
            border-radius: 4px;
        }}
        
        .issue-item.error {{
            border-left-color: #dc3545;
            background: #fff5f5;
        }}
        
        .issue-item.warning {{
            border-left-color: #ffc107;
            background: #fffbf0;
        }}
        
        .issue-header {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
        }}
        
        .issue-file {{
            font-weight: bold;
            color: #333;
            flex-grow: 1;
        }}
        
        .issue-severity {{
            display: inline-block;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 0.85em;
            font-weight: bold;
            text-transform: uppercase;
        }}
        
        .severity-error {{
            background: #dc3545;
            color: white;
        }}
        
        .severity-warning {{
            background: #ffc107;
            color: black;
        }}
        
        .issue-message {{
            color: #555;
            font-size: 0.95em;
            line-height: 1.5;
        }}
        
        .no-issues {{
            color: #28a745;
            font-size: 1.1em;
            padding: 20px;
            text-align: center;
        }}
        
        footer {{
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #6c757d;
            border-top: 1px solid #e9ecef;
        }}
        
        @media (max-width: 768px) {{
            header h1 {{
                font-size: 1.8em;
            }}
            
            .summary {{
                grid-template-columns: 1fr;
            }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>IAC Scan Report</h1>
            <p>Infrastructure as Code Security Assessment</p>
        </header>
        
        <div class="summary">
            <div class="stat-card">
                <h3>{total_issues}</h3>
                <p>Total Issues</p>
            </div>
            <div class="stat-card error">
                <h3>{errors}</h3>
                <p>Errors</p>
            </div>
            <div class="stat-card warning">
                <h3>{warnings}</h3>
                <p>Warnings</p>
            </div>
            <div class="stat-card success">
                <h3>{len([r for r in scan_results if r.get('status') == 'success'])}</h3>
                <p>Scans Passed</p>
            </div>
        </div>
        
        <div class="content">
            {''.join(self._generate_tool_section(r) for r in scan_results)}
        </div>
        
        <footer>
            <p>Report generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
            <p>IAC Security Assessment Tool</p>
        </footer>
    </div>
</body>
</html>"""
        
        # Save report
        report_file = self.output_dir / f"iac-scan-report-{self.timestamp}.html"
        with open(report_file, "w") as f:
            f.write(html_content)
        
        print(f"Report saved to: {report_file}")
        return str(report_file)
    
    def _generate_tool_section(self, tool_result: Dict[str, Any]) -> str:
        """Generate HTML section for a tool"""
        tool_name = tool_result.get("tool", "Unknown Tool")
        status = tool_result.get("status", "unknown")
        issues = tool_result.get("issues", [])
        
        status_class = f"status-{status}"
        status_badge = f'<span class="tool-status {status_class}">{status.upper()}</span>'
        
        if status == "skipped":
            issues_html = f'<p class="no-issues">⏭️ {tool_name} is not available (not installed)</p>'
        elif not issues:
            issues_html = f'<p class="no-issues">✅ No issues found</p>'
        else:
            issues_html = '<ul class="issues-list">'
            for issue in issues:
                severity = issue.get("severity", "warning").lower()
                issue_class = f"issue-item {severity}"
                
                severity_class = f"severity-{severity}"
                severity_badge = f'<span class="issue-severity {severity_class}">{severity}</span>'
                
                file_info = f"<span class=\"issue-file\">{issue.get('file', 'Unknown')}</span>"
                if issue.get('line'):
                    file_info += f" <span style='color: #999;'>:{issue.get('line')}</span>"
                
                message_parts = []
                if issue.get('issue'):
                    message_parts.append(f"<strong>{issue.get('issue')}</strong>")
                if issue.get('message'):
                    message_parts.append(issue.get('message'))
                if issue.get('error'):
                    message_parts.append(issue.get('error'))
                if issue.get('detail'):
                    message_parts.append(issue.get('detail'))
                
                message = " | ".join(message_parts)
                
                issues_html += f"""
                <li class="{issue_class}">
                    <div class="issue-header">
                        {file_info}
                        {severity_badge}
                    </div>
                    <div class="issue-message">{message}</div>
                </li>
                """
            issues_html += '</ul>'
        
        return f"""
        <div class="scan-section">
            <h2>
                {tool_name}
                {status_badge}
            </h2>
            {issues_html}
        </div>
        """


def main():
    workspace_root = Path(__file__).parent.parent
    
    print(f"Workspace: {workspace_root}")
    
    # Initialize scanner
    scanner = IACScanner(str(workspace_root))
    
    # Run all scans
    scan_results = scanner.run_all_scans()
    
    # Generate report
    report_path = scanner.generate_html_report(scan_results)
    
    print(f"\n Scan complete! Report: {report_path}\n")
    
    # Return exit code based on results
    has_errors = any(
        issue.get("severity") == "error"
        for result in scan_results
        for issue in result.get("issues", [])
    )
    
    return 1 if has_errors else 0


if __name__ == "__main__":
    sys.exit(main())
