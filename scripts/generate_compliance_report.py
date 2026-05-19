#!/usr/bin/env python3
"""
Generate combined HTML compliance report from Checkov, TFLint, and OPA results
"""

import json
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, List, Optional

class ComplianceReportGenerator:
    def __init__(self, reports_dir: str = "reports"):
        self.reports_dir = Path(reports_dir)
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
    def load_checkov_results(self) -> Dict[str, Any]:
        """Load Checkov SARIF results"""
        checkov_file = self.reports_dir / "checkov.sarif"
        
        if not checkov_file.exists():
            return {
                "tool": "Checkov",
                "status": "not-found",
                "issues": [],
                "timestamp": datetime.now().isoformat()
            }
        
        try:
            with open(checkov_file, 'r') as f:
                sarif_data = json.load(f)
            
            results = {
                "tool": "Checkov",
                "status": "success",
                "issues": [],
                "timestamp": datetime.now().isoformat()
            }
            
            if sarif_data.get("runs") and sarif_data["runs"]:
                run = sarif_data["runs"][0]
                for result in run.get("results", []):
                    issue = {
                        "rule_id": result.get("ruleId", "Unknown"),
                        "message": result.get("message", {}).get("text", ""),
                        "level": result.get("level", "warning"),
                        "location": result.get("locations", [{}])[0].get("physicalLocation", {}).get("artifactLocation", {}).get("uri", "Unknown"),
                        "severity": "error" if result.get("level") == "error" else "warning"
                    }
                    results["issues"].append(issue)
            
            return results
            
        except Exception as e:
            return {
                "tool": "Checkov",
                "status": "error",
                "issues": [{"error": str(e)}],
                "timestamp": datetime.now().isoformat()
            }
    
    def load_tflint_results(self) -> Dict[str, Any]:
        """Load TFLint JSON results"""
        tflint_file = self.reports_dir / "tflint-report.json"
        
        if not tflint_file.exists():
            return {
                "tool": "TFLint",
                "status": "not-found",
                "issues": [],
                "timestamp": datetime.now().isoformat()
            }
        
        try:
            with open(tflint_file, 'r') as f:
                tflint_data = json.load(f)
            
            results = {
                "tool": "TFLint",
                "status": "success",
                "issues": [],
                "timestamp": datetime.now().isoformat()
            }
            
            for issue in tflint_data.get("issues", []):
                result_issue = {
                    "rule_id": issue.get("rule", {}).get("name", "Unknown"),
                    "message": issue.get("message", ""),
                    "level": issue.get("rule", {}).get("severity", "notice").lower(),
                    "location": f"{issue.get('range', {}).get('filename', 'Unknown')}:{issue.get('range', {}).get('start', {}).get('line', 0)}",
                    "severity": "error" if issue.get("rule", {}).get("severity", "").lower() == "error" else "warning" if issue.get("rule", {}).get("severity", "").lower() == "warning" else "info"
                }
                results["issues"].append(result_issue)
            
            return results
            
        except Exception as e:
            return {
                "tool": "TFLint",
                "status": "error",
                "issues": [{"error": str(e)}],
                "timestamp": datetime.now().isoformat()
            }
    
    def load_opa_results(self) -> Dict[str, Any]:
        """Load OPA policy results"""
        opa_file = self.reports_dir / "opa-results.json"
        
        if not opa_file.exists():
            return {
                "tool": "OPA/Rego",
                "status": "not-found",
                "issues": [],
                "timestamp": datetime.now().isoformat()
            }
        
        try:
            with open(opa_file, 'r') as f:
                opa_data = json.load(f)
            
            results = {
                "tool": "OPA/Rego",
                "status": "success",
                "issues": [],
                "timestamp": datetime.now().isoformat()
            }
            
            # Parse OPA output
            if "result" in opa_data and opa_data["result"]:
                for item in opa_data["result"]:
                    if "expressions" in item:
                        for expr in item["expressions"]:
                            if "value" in expr:
                                denies = expr["value"] if isinstance(expr["value"], list) else [expr["value"]]
                                for deny in denies:
                                    if deny:
                                        results["issues"].append({
                                            "rule_id": "OPA Policy Violation",
                                            "message": str(deny),
                                            "level": "error",
                                            "severity": "error"
                                        })
            
            return results
            
        except Exception as e:
            return {
                "tool": "OPA/Rego",
                "status": "error",
                "issues": [{"error": str(e)}],
                "timestamp": datetime.now().isoformat()
            }
    
    def generate_html_report(self, all_results: List[Dict[str, Any]]) -> str:
        """Generate combined HTML report"""
        
        # Calculate statistics
        total_issues = sum(len(r.get("issues", [])) for r in all_results)
        errors = sum(1 for r in all_results for i in r.get("issues", []) if i.get("severity") == "error")
        warnings = sum(1 for r in all_results for i in r.get("issues", []) if i.get("severity") == "warning")
        
        html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Infrastructure Compliance Report</title>
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
            max-width: 1400px;
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
        }}
        
        .stat-card {{
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            text-align: center;
            border-top: 4px solid #667eea;
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
        
        .stat-card.error {{
            border-top-color: #dc3545;
        }}
        
        .stat-card.error h3 {{
            color: #dc3545;
        }}
        
        .stat-card.warning {{
            border-top-color: #ffc107;
        }}
        
        .stat-card.warning h3 {{
            color: #ffc107;
        }}
        
        .stat-card.success {{
            border-top-color: #28a745;
        }}
        
        .stat-card.success h3 {{
            color: #28a745;
        }}
        
        .content {{
            padding: 30px 20px;
        }}
        
        .section {{
            margin-bottom: 40px;
        }}
        
        .section h2 {{
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #e9ecef;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }}
        
        .tool-status {{
            display: inline-block;
            padding: 5px 10px;
            border-radius: 4px;
            font-size: 0.8em;
            font-weight: bold;
            margin-left: auto;
        }}
        
        .tool-status.success {{
            background: #28a745;
            color: white;
        }}
        
        .tool-status.error {{
            background: #dc3545;
            color: white;
        }}
        
        .tool-status.warning {{
            background: #ffc107;
            color: black;
        }}
        
        .tool-status.not-found {{
            background: #6c757d;
            color: white;
        }}
        
        .issues-list {{
            list-style: none;
        }}
        
        .issue-item {{
            background: #f8f9fa;
            padding: 15px;
            margin-bottom: 10px;
            border-left: 4px solid #6c757d;
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
        
        .issue-item.info {{
            border-left-color: #17a2b8;
            background: #f0f7ff;
        }}
        
        .issue-header {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
        }}
        
        .issue-severity {{
            display: inline-block;
            padding: 3px 8px;
            border-radius: 3px;
            font-size: 0.75em;
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
        
        .severity-info {{
            background: #17a2b8;
            color: white;
        }}
        
        .issue-message {{
            color: #333;
            line-height: 1.5;
        }}
        
        .issue-detail {{
            color: #6c757d;
            font-size: 0.9em;
            margin-top: 5px;
        }}
        
        .no-issues {{
            text-align: center;
            padding: 20px;
            color: #28a745;
            font-weight: bold;
        }}
        
        .timestamp {{
            text-align: right;
            color: #6c757d;
            font-size: 0.9em;
            margin-top: 40px;
            padding-top: 20px;
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
            <h1>🔍 Infrastructure Compliance Report</h1>
            <p>Terraform IaC Scanning & Compliance Assessment</p>
        </header>
        
        <div class="summary">
            <div class="stat-card">
                <h3>{total_issues}</h3>
                <p>Total Issues Found</p>
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
                <h3>{len(all_results)}</h3>
                <p>Scans Completed</p>
            </div>
        </div>
        
        <div class="content">
"""
        
        # Add tool sections
        for tool_result in all_results:
            tool_name = tool_result.get("tool", "Unknown")
            status = tool_result.get("status", "unknown")
            issues = tool_result.get("issues", [])
            
            status_class = f"status-{status}"
            status_badge = f'<span class="tool-status {status_class}">{status.upper()}</span>'
            
            html_content += f'<div class="section"><h2>{tool_name} {status_badge}</h2>'
            
            if status == "not-found":
                html_content += '<p class="no-issues">⏭️ No report file found</p>'
            elif not issues:
                html_content += '<p class="no-issues">✅ No issues found</p>'
            else:
                html_content += '<ul class="issues-list">'
                for issue in issues:
                    severity = issue.get("severity", "warning").lower()
                    issue_class = f"issue-item {severity}"
                    severity_badge = f'<span class="issue-severity severity-{severity}">{severity}</span>'
                    
                    rule_id = issue.get("rule_id", "Unknown")
                    message = issue.get("message", "")
                    location = issue.get("location", "")
                    
                    location_html = f'<div class="issue-detail">📍 {location}</div>' if location else ''
                    
                    html_content += f'''<li class="{issue_class}">
                        <div class="issue-header">
                            <strong>{rule_id}</strong>
                            {severity_badge}
                        </div>
                        <div class="issue-message">{message}</div>
                        {location_html}
                    </li>'''
                
                html_content += '</ul>'
            
            html_content += '</div>'
        
        html_content += f"""
        </div>
        
        <div class="timestamp">
            Generated on {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
        </div>
    </div>
</body>
</html>
"""
        
        return html_content
    
    def generate(self) -> str:
        """Generate complete compliance report"""
        print("\n Generating Compliance Report...")
        
        # Load all results
        results = [
            self.load_checkov_results(),
            self.load_tflint_results(),
            self.load_opa_results()
        ]
        
        # Generate HTML
        html_content = self.generate_html_report(results)
        
        # Save report
        output_file = self.reports_dir / f"compliance-report-{self.timestamp}.html"
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_file, 'w') as f:
            f.write(html_content)
        
        print(f"✅ Report generated: {output_file}")
        return str(output_file)


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Generate compliance report from scan results")
    parser.add_argument("--reports-dir", default="reports", help="Directory containing scan reports")
    
    args = parser.parse_args()
    
    generator = ComplianceReportGenerator(args.reports_dir)
    report_file = generator.generate()
    
    print(f"\n📄 Report saved to: {report_file}")


if __name__ == "__main__":
    main()
