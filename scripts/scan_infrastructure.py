#!/usr/bin/env python3
"""
Combined IAC + AWS Infrastructure Scanner
Runs all scans and generates unified reports
"""

import sys
from pathlib import Path
from datetime import datetime

# Add scripts directory to path
sys.path.insert(0, str(Path(__file__).parent))

from run_scans import IACScanner
from aws_scan import AWSInfrastructureScanner

def generate_combined_html_report(iac_results, aws_results, output_dir):
    """Generate combined HTML report for IAC and AWS infrastructure scans"""
    
    total_issues = sum(len(r.get("issues", [])) for r in iac_results + aws_results)
    errors = sum(1 for r in iac_results + aws_results for i in r.get("issues", []) if i.get("severity") == "error")
    warnings = sum(1 for r in iac_results + aws_results for i in r.get("issues", []) if i.get("severity") == "warning")
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Complete IAC + AWS Infrastructure Scan Report</title>
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
        
        .tabs {{
            display: flex;
            border-bottom: 2px solid #e9ecef;
            background: #f8f9fa;
        }}
        
        .tab-button {{
            flex: 1;
            padding: 15px;
            text-align: center;
            background: none;
            border: none;
            cursor: pointer;
            font-size: 1em;
            font-weight: 500;
            color: #666;
            transition: all 0.3s;
        }}
        
        .tab-button.active {{
            color: #667eea;
            border-bottom: 3px solid #667eea;
            margin-bottom: -2px;
        }}
        
        .tab-button:hover {{
            color: #667eea;
            background: white;
        }}
        
        .tab-content {{
            display: none;
            padding: 30px 20px;
        }}
        
        .tab-content.active {{
            display: block;
        }}
        
        .summary {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
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
        
        .section {{
            margin-bottom: 30px;
        }}
        
        .section h2 {{
            color: #333;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }}
        
        .tool-status {{
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: bold;
            text-transform: uppercase;
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
            flex-wrap: wrap;
            gap: 10px;
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
            background: #f0f8f4;
            border-radius: 4px;
        }}
        
        footer {{
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #6c757d;
            border-top: 1px solid #e9ecef;
        }}
        
        .finding-card {{
            background: #f8f9fa;
            border-left: 4px solid #ffc107;
            padding: 15px;
            margin-bottom: 10px;
            border-radius: 4px;
        }}
        
        .finding-level {{
            display: inline-block;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 0.85em;
            font-weight: bold;
            text-transform: uppercase;
            margin-right: 8px;
        }}
        
        .finding-level.high {{
            background: #dc3545;
            color: white;
        }}
        
        .finding-level.medium {{
            background: #ffc107;
            color: black;
        }}
        
        .finding-level.low {{
            background: #17a2b8;
            color: white;
        }}
        
        @media (max-width: 768px) {{
            header h1 {{
                font-size: 1.8em;
            }}
            
            .summary {{
                grid-template-columns: 1fr;
            }}
            
            .tabs {{
                flex-direction: column;
            }}
            
            .tab-button {{
                border-bottom: none;
                border-right: 3px solid #e9ecef;
            }}
            
            .tab-button.active {{
                border-right-color: #667eea;
                border-bottom: none;
                margin-bottom: 0;
            }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🔒 Infrastructure Security Report</h1>
            <p>Complete IAC + AWS Infrastructure Assessment</p>
        </header>
        
        <div class="tabs">
            <button class="tab-button active" onclick="switchTab('overview')">📊 Overview</button>
            <button class="tab-button" onclick="switchTab('iac')">📋 IAC Scans</button>
            <button class="tab-button" onclick="switchTab('aws')">☁️ AWS Infrastructure</button>
        </div>
        
        <div id="overview" class="tab-content active">
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
                    <h3>{len([r for r in iac_results + aws_results if r.get('status') == 'success'])}</h3>
                    <p>Scans Completed</p>
                </div>
            </div>
            
            <div class="section">
                <h2>📋 IAC Scans Summary</h2>
                {''.join(f"<p>• {r.get('tool')}: <strong>{r.get('status').upper()}</strong></p>" for r in iac_results)}
            </div>
            
            <div class="section">
                <h2>☁️ AWS Infrastructure Summary</h2>
                {''.join(f"<p>• {r.get('tool')}: <strong>{r.get('status').upper()}</strong></p>" for r in aws_results)}
            </div>
        </div>
        
        <div id="iac" class="tab-content">
            <div class="summary">
                <div class="stat-card">
                    <h3>{sum(len(r.get("issues", [])) for r in iac_results)}</h3>
                    <p>IAC Issues</p>
                </div>
            </div>
            {''.join(_generate_tool_section(r) for r in iac_results)}
        </div>
        
        <div id="aws" class="tab-content">
            <div class="summary">
                <div class="stat-card">
                    <h3>{sum(len(r.get("issues", [])) for r in aws_results)}</h3>
                    <p>AWS Issues</p>
                </div>
            </div>
            {''.join(_generate_aws_tool_section(r) for r in aws_results)}
        </div>
        
        <footer>
            <p>Report generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
            <p>Infrastructure Security Assessment Tool</p>
        </footer>
    </div>
    
    <script>
        function switchTab(tab) {{
            // Hide all tabs
            document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
            document.querySelectorAll('.tab-button').forEach(el => el.classList.remove('active'));
            
            // Show selected tab
            document.getElementById(tab).classList.add('active');
            event.target.classList.add('active');
        }}
    </script>
</body>
</html>"""
    
    report_file = Path(output_dir) / f"security-report-combined-{timestamp}.html"
    with open(report_file, "w") as f:
        f.write(html_content)
    
    return str(report_file)

def _generate_tool_section(tool_result):
    """Generate HTML section for IAC tool"""
    tool_name = tool_result.get("tool", "Unknown Tool")
    status = tool_result.get("status", "unknown")
    issues = tool_result.get("issues", [])
    
    status_class = f"status-{status}"
    status_badge = f'<span class="tool-status {status_class}">{status.upper()}</span>'
    
    if status == "skipped":
        issues_html = f'<p class="no-issues">⏭️ {tool_name} is not available</p>'
    elif not issues:
        issues_html = f'<p class="no-issues">✅ No issues found</p>'
    else:
        issues_html = '<ul class="issues-list">'
        for issue in issues:
            severity = issue.get("severity", "warning").lower()
            issue_class = f"issue-item {severity}"
            severity_badge = f'<span class="issue-severity severity-{severity}">{severity}</span>'
            
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
            issues_html += f'<li class="{issue_class}"><div class="issue-header">{file_info}{severity_badge}</div><div class="issue-message">{message}</div></li>'
        
        issues_html += '</ul>'
    
    return f'<div class="section"><h2>{tool_name} <span style="margin-left: auto;">{status_badge}</span></h2>{issues_html}</div>'

def _generate_aws_tool_section(tool_result):
    """Generate HTML section for AWS tool"""
    tool_name = tool_result.get("tool", "Unknown Tool")
    status = tool_result.get("status", "unknown")
    issues = tool_result.get("issues", [])
    findings = tool_result.get("findings", [])
    
    status_class = f"status-{status}"
    status_badge = f'<span class="tool-status {status_class}">{status.upper()}</span>'
    
    if status == "skipped":
        content = f'<p class="no-issues">⏭️ {tool_name} is not installed</p>'
    elif status == "failed" and issues:
        content = '<ul class="issues-list">'
        for issue in issues:
            content += f'<li class="issue-item error"><div class="issue-message">{issue.get("error", "Unknown error")}</div></li>'
        content += '</ul>'
    elif findings:
        content = '<ul class="issues-list">'
        for finding in findings:
            level_class = f"finding-level {finding.get('level', 'low').lower()}"
            content += f'''<li class="finding-card">
                <div><span class="{level_class}">{finding.get('level', 'Unknown').upper()}</span></div>
                <div style="font-weight: bold; margin-top: 8px;">{finding.get('title', 'Unknown Finding')}</div>
                <div style="color: #666; font-size: 0.9em; margin-top: 4px;">
                    Service: {finding.get('service', 'Unknown')} | 
                    Affected items: {finding.get('affected_items', 0)}
                </div>
            </li>'''
        content += '</ul>'
    else:
        content = f'<p class="no-issues">✅ No significant findings</p>'
    
    return f'<div class="section"><h2>{tool_name} <span style="margin-left: auto;">{status_badge}</span></h2>{content}</div>'

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Run combined IAC and AWS infrastructure scans")
    parser.add_argument("--profile", help="AWS profile to use", default=None)
    parser.add_argument("--iac-only", action="store_true", help="Run only IAC scans")
    parser.add_argument("--aws-only", action="store_true", help="Run only AWS infrastructure scans")
    
    args = parser.parse_args()
    
    workspace_root = Path(__file__).parent.parent
    
    iac_results = []
    aws_results = []
    
    if not args.aws_only:
        print("\n" + "="*60)
        print("INFRASTRUCTURE AS CODE SCANS")
        print("="*60)
        iac_scanner = IACScanner(str(workspace_root))
        iac_results = iac_scanner.run_all_scans()
        iac_report = iac_scanner.generate_html_report(iac_results)
        print(f"\nIAC Report: {iac_report}")
    
    if not args.iac_only:
        print("\n" + "="*60)
        print("AWS INFRASTRUCTURE SCANS")
        print("="*60)
        aws_scanner = AWSInfrastructureScanner(profile=args.profile)
        aws_results = aws_scanner.run_all_scans()
    
    if iac_results or aws_results:
        print("\n" + "="*60)
        print("GENERATING COMBINED REPORT")
        print("="*60)
        combined_report = generate_combined_html_report(
            iac_results,
            aws_results,
            str(workspace_root / "scan-reports")
        )
        print(f"Combined Report: {combined_report}")
    
    print("\n✅ All scans complete!")
    
    has_errors = any(
        issue.get("severity") == "error"
        for result in (iac_results + aws_results)
        for issue in result.get("issues", [])
    )
    
    return 1 if has_errors else 0


if __name__ == "__main__":
    sys.exit(main())
