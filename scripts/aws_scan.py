#!/usr/bin/env python3
"""
AWS Infrastructure Scanner using ScoutSuite
Scans live AWS infrastructure for security issues and misconfigurations
"""

import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List

class AWSInfrastructureScanner:
    def __init__(self, output_dir: str = "scan-reports", profile: str = None):
        """
        Initialize AWS Scanner
        
        Args:
            output_dir: Directory to save reports
            profile: AWS profile to use (default: default profile)
        """
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.profile = profile
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.env = self._setup_env()
        
    def _setup_env(self) -> Dict:
        """Setup environment variables"""
        import os
        env = os.environ.copy()
        if self.profile:
            env['AWS_PROFILE'] = self.profile
        return env
    
    def _check_tool_installed(self, tool_name: str, import_name: str = None, cli_command: str = None) -> bool:
        """Check if a tool is installed via import or CLI"""
        # Try import first
        if import_name:
            try:
                __import__(import_name)
                return True
            except ImportError:
                pass
        
        # Try CLI command
        if cli_command:
            try:
                result = subprocess.run(
                    [cli_command, "--version"],
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                return result.returncode == 0
            except (FileNotFoundError, subprocess.TimeoutExpired):
                pass
        
        # Try pip show
        try:
            result = subprocess.run(
                ["pip", "show", tool_name],
                capture_output=True,
                text=True,
                timeout=5
            )
            return result.returncode == 0
        except:
            pass
        
        return False
    
    def run_scoutsuite(self) -> Dict[str, Any]:
        """Run ScoutSuite AWS security audit"""
        print("\n🔍 Running ScoutSuite AWS Security Audit...")
        results = {
            "tool": "ScoutSuite",
            "status": "success",
            "issues": [],
            "timestamp": datetime.now().isoformat(),
            "report_file": None
        }
        
        try:
            # Check if scoutsuite is installed
            if not self._check_tool_installed("scoutsuite", "scout", "scout"):
                print("⚠️  ScoutSuite not installed, skipping")
                return {
                    "tool": "ScoutSuite",
                    "status": "skipped",
                    "issues": [],
                    "timestamp": datetime.now().isoformat()
                }
            
            # Run scoutsuite
            report_dir = self.output_dir / f"scoutsuite-{self.timestamp}"
            report_dir.mkdir(parents=True, exist_ok=True)
            
            cmd = [
                "scout",
                "aws",
                "--report-dir", str(report_dir),
                "--no-browser",
                "--quiet"
            ]
            
            print(f"  Command: {' '.join(cmd)}")
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=600,  # 10 minutes timeout
                env=self.env
            )
            
            if result.returncode != 0:
                # ScoutSuite returns non-zero if there are issues, which is expected
                if "Error" not in result.stderr and "error" not in result.stderr:
                    print(f"✓ ScoutSuite completed")
                else:
                    results["status"] = "failed"
                    results["issues"].append({
                        "error": result.stderr,
                        "severity": "error"
                    })
            
            # Parse ScoutSuite JSON report
            report_file = report_dir / "aws-scout-summary.json"
            if report_file.exists():
                with open(report_file, 'r') as f:
                    scout_data = json.load(f)
                    results["report_file"] = str(report_file)
                    
                    # Extract findings from ScoutSuite
                    results["findings"] = self._parse_scoutsuite_findings(scout_data)
                    
                    print(f"✓ ScoutSuite completed - Found {len(results['findings'])} findings")
            else:
                print(f"✓ ScoutSuite completed - HTML report generated")
                
        except subprocess.TimeoutExpired:
            results["status"] = "failed"
            results["issues"].append({
                "error": "ScoutSuite scan timeout (>10 minutes)",
                "severity": "warning"
            })
        except FileNotFoundError:
            print("⚠️  ScoutSuite not installed")
            results["status"] = "skipped"
        except Exception as e:
            results["status"] = "failed"
            results["issues"].append({
                "error": str(e),
                "severity": "error"
            })
        
        return results
    
    def _parse_scoutsuite_findings(self, data: Dict) -> List[Dict]:
        """Parse ScoutSuite findings from report"""
        findings = []
        
        # Extract from services if available
        services = data.get("services", {})
        for service_name, service_data in services.items():
            if isinstance(service_data, dict):
                findings_list = service_data.get("findings", [])
                if isinstance(findings_list, dict):
                    for finding_id, finding_data in findings_list.items():
                        if isinstance(finding_data, dict):
                            findings.append({
                                "service": service_name,
                                "finding_id": finding_id,
                                "title": finding_data.get("title", "Unknown"),
                                "level": finding_data.get("level", "unknown"),
                                "affected_items": len(finding_data.get("items", []))
                            })
        
        return findings
    
    def run_prowler(self) -> Dict[str, Any]:
        """Run Prowler for AWS security assessment"""
        print("\n🔐 Running Prowler AWS Security Assessment...")
        results = {
            "tool": "Prowler",
            "status": "success",
            "issues": [],
            "timestamp": datetime.now().isoformat()
        }
        
        try:
            # Check if prowler is installed
            if not self._check_tool_installed("prowler", "prowler", "prowler"):
                print("⚠️  Prowler not installed, skipping")
                return {
                    "tool": "Prowler",
                    "status": "skipped",
                    "issues": [],
                    "timestamp": datetime.now().isoformat()
                }
            
            # Create output directory
            output_dir = self.output_dir / f"prowler-{self.timestamp}"
            output_dir.mkdir(parents=True, exist_ok=True)
            
            # Run prowler
            cmd = [
                "prowler",
                "-g", "cis_level2_aws",  # CIS Foundations Benchmark v1.2.0
                "-f", str(output_dir),
                "-z"  # Zip output
            ]
            
            print(f"  Command: {' '.join(cmd)}")
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=600,  # 10 minutes timeout
                env=self.env
            )
            
            if result.returncode == 0 or "Assessment" in result.stdout:
                print(f"✓ Prowler completed")
            else:
                results["status"] = "failed"
                results["issues"].append({
                    "error": result.stderr or result.stdout,
                    "severity": "warning"
                })
            
        except subprocess.TimeoutExpired:
            results["status"] = "failed"
            results["issues"].append({
                "error": "Prowler scan timeout (>10 minutes)",
                "severity": "warning"
            })
        except FileNotFoundError:
            print("⚠️  Prowler not installed")
            results["status"] = "skipped"
        except Exception as e:
            results["status"] = "failed"
            results["issues"].append({
                "error": str(e),
                "severity": "error"
            })
        
        return results
    
    def run_all_scans(self) -> List[Dict[str, Any]]:
        """Run all AWS infrastructure scans"""
        print(f"\n🚀 Starting AWS Infrastructure Scans at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"   AWS Profile: {self.profile or 'default'}")
        
        scan_results = [
            self.run_scoutsuite(),
            self.run_prowler()
        ]
        
        return scan_results


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Scan live AWS infrastructure")
    parser.add_argument("--profile", help="AWS profile to use", default=None)
    parser.add_argument("--output-dir", help="Output directory for reports", default="scan-reports")
    
    args = parser.parse_args()
    
    scanner = AWSInfrastructureScanner(
        output_dir=args.output_dir,
        profile=args.profile
    )
    
    results = scanner.run_all_scans()
    
    print(f"\n✅ AWS Infrastructure scans complete!")
    print(f"   Reports saved to: {scanner.output_dir}")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
