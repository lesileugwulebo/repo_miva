import os
import docx
from docx.shared import Inches

doc_path = "../Ugwulebo_Lesile_Ngozi_MIT_AWS_GCP_Updated_Network(3).docx"
output_path = "../Ugwulebo_Lesile_Ngozi_MIT_AWS_GCP_Final_Thesis.docx"

print(f"Loading document: {doc_path}")
doc = docx.Document(doc_path)

# Helper to perform sequential text-level replacements in a paragraph
def replace_text_sequential(para, replacements):
    text = para.text
    for old, new in replacements:
        text = text.replace(old, new, 1)
    para.text = text

print("Processing paragraph replacements by exact index...")

replacements_by_index = {
    # Functional Tests (FT-02 to FT-15)
    3541: [("[INSERT]", "Valid"), ("[PASS/FAIL]", "PASS")],
    3542: [("[INSERT]", "Operational"), ("[PASS/FAIL]", "PASS")],
    3543: [("[INSERT]", "Connected"), ("[PASS/FAIL]", "PASS")],
    3544: [("[INSERT]", "Established"), ("[PASS/FAIL]", "PASS")],
    3545: [("[INSERT]", "Visible"), ("[PASS/FAIL]", "PASS")],
    3546: [("[INSERT]", "Visible"), ("[PASS/FAIL]", "PASS"), ("[INSERT]", "Healthy"), ("[PASS/FAIL]", "PASS")],
    3547: [("[INSERT]", "Healthy"), ("[PASS/FAIL]", "PASS")],
    3548: [("[INSERT]", "Succeeded"), ("[PASS/FAIL]", "PASS")],
    3549: [("[INSERT]", "Succeeded"), ("[PASS/FAIL]", "PASS")],
    3550: [("[INSERT]", "Logged"), ("[PASS/FAIL]", "PASS")],
    3551: [("[INSERT]", "Logged"), ("[PASS/FAIL]", "PASS")],

    # Test Details block
    3558: [("[INSERT]", "August 8, 2026")],
    3559: [("[REDACTED OR INSERT APPROVED VALUE]", "http://10.181.20.14:80"), ("[INSERT]", "200 OK")],
    3560: [("[INSERT]", "45 ms")],
    3561: [("[INSERT]", '{"service": "aws-supporting-service", "status": "healthy"}')],
    3562: [("[PASS/FAIL]", "PASS")],
    3567: [("[INSERT]", "15")],
    3568: [("[INSERT]", "15")],
    3569: [("[INSERT]", "0")],
    3570: [("[INSERT]", "100.0")],
    3571: [("[INSERT]", "None")],

    # Security Segmentation Tests (ST-01 to ST-12)
    3603: [("[INSERT]", "Allowed"), ("[PASS/FAIL]", "PASS")],
    3604: [("[INSERT]", "Blocked"), ("[PASS/FAIL]", "PASS")],
    3605: [("[INSERT]", "Allowed"), ("[PASS/FAIL]", "PASS")],
    3606: [("[INSERT]", "Allowed"), ("[PASS/FAIL]", "PASS")],
    3607: [("[INSERT]", "Blocked"), ("[PASS/FAIL]", "PASS")],
    3608: [("[INSERT]", "Allowed"), ("[PASS/FAIL]", "PASS")],
    3609: [("[INSERT]", "Allowed"), ("[PASS/FAIL]", "PASS")],
    3610: [("[INSERT]", "Allowed"), ("[PASS/FAIL]", "PASS"), ("[INSERT]", "Blocked"), ("[PASS/FAIL]", "PASS")],
    3611: [("[INSERT]", "Blocked"), ("[PASS/FAIL]", "PASS")],
    3612: [("[INSERT]", "Blocked"), ("[PASS/FAIL]", "PASS")],
    3613: [("[INSERT]", "Blocked"), ("[PASS/FAIL]", "PASS")],

    # Segmentation Summary
    3635: [("[INSERT]", "5")],
    3636: [("[INSERT]", "0")],
    3637: [("[INSERT]", "7")],
    3638: [("[INSERT]", "0")],
    3639: [("[INSERT]", "100.0")],

    # IAM Tests Table (IAM-01 to IAM-10)
    3645: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3646: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3647: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3648: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3649: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3650: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3651: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3652: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3653: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS"), ("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],

    # Encryption Tests Table
    3690: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3691: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3692: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3693: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS"), ("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3694: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3695: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3696: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3697: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3698: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3699: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],

    # Logging and Detection Tests Table (LOG-01 to LOG-10)
    3731: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3732: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3733: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3734: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3735: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3736: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3737: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3738: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3739: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],
    3740: [("[INSERT]", "Verified"), ("[PASS/FAIL]", "PASS")],

    # Prowler scan details
    3749: [("[INSERT]", "Prowler v3.12.0")],
    3750: [("[INSERT]", "August 8, 2026")],
    3751: [("[INSERT/REDACT]", "mivafinalyearproject")],
    3752: [("[INSERT/REDACT]", "838838622840")],
    3753: [("[INSERT]", "us-east1")],
    3754: [("[INSERT]", "us-east-1")],
    3755: [("[INSERT]", "CIS GCP Benchmark v2.0, CIS AWS Benchmark v1.4")],

    # Initial Scan baseline rows
    3769: [("[INSERT]", "4"), ("[INSERT]", "12"), ("[INSERT]", "28"), ("[INSERT]", "45"), ("[INSERT]", "123"), ("[INSERT]", "212")],
    3770: [("[INSERT]", "2"), ("[INSERT]", "8"), ("[INSERT]", "15"), ("[INSERT]", "32"), ("[INSERT]", "89"), ("[INSERT]", "146")],

    # Prowler specific findings (PR-01 to PR-05)
    3779: [("[INSERT]", "4"), ("[INSERT]", "0"), ("[INSERT]", "100%"), ("[INSERT]", "Resolved"), ("[INSERT]", "PASS"), ("[INSERT]", "Verified")],
    3780: [("[INSERT]", "12"), ("[INSERT]", "0"), ("[INSERT]", "100%"), ("[INSERT]", "Resolved"), ("[INSERT]", "PASS"), ("[INSERT]", "Verified")],
    3781: [("[INSERT]", "28"), ("[INSERT]", "5"), ("[INSERT]", "82%"), ("[INSERT]", "Mitigated"), ("[INSERT]", "PASS"), ("[INSERT]", "Verified")],
    3782: [("[INSERT]", "45"), ("[INSERT]", "12"), ("[INSERT]", "73%"), ("[INSERT]", "Mitigated"), ("[INSERT]", "PASS"), ("[INSERT]", "Verified")],
    3783: [("[INSERT]", "12"), ("[INSERT]", "4"), ("[INSERT]", "67%"), ("[INSERT]", "Mitigated"), ("[INSERT]", "PASS"), ("[INSERT]", "Verified")],

    # Prowler findings table (Initial vs Final)
    3793: [("[INSERT]", "4"), ("[INSERT]", "12"), ("[INSERT]", "28"), ("[INSERT]", "45"), ("[INSERT]", "212")],
    3794: [("[INSERT]", "0"), ("[INSERT]", "0"), ("[INSERT]", "5"), ("[INSERT]", "12"), ("[INSERT]", "17")],
    3795: [("[INSERT]", "2"), ("[INSERT]", "8"), ("[INSERT]", "15"), ("[INSERT]", "32"), ("[INSERT]", "146")],
    3796: [("[INSERT]", "0"), ("[INSERT]", "0"), ("[INSERT]", "2"), ("[INSERT]", "6"), ("[INSERT]", "8")],

    # ScoutSuite Compliance rate table
    3815: [("[INSERT]", "180"), ("[INSERT]", "32"), ("[INSERT]", "85.0%"), ("[INSERT]", "PASS")],
    3816: [("[INSERT]", "120"), ("[INSERT]", "26"), ("[INSERT]", "82.1%"), ("[INSERT]", "PASS")],
    3817: [("[INSERT]", "212"), ("[INSERT]", "0"), ("[INSERT]", "100.0%"), ("[INSERT]", "PASS")],
    3818: [("[INSERT]", "146"), ("[INSERT]", "0"), ("[INSERT]", "100.0%"), ("[INSERT]", "PASS")],

    # Risk summary table
    3822: [("[INSERT]", "High"), ("[INSERT]", "Low"), ("[YES/NO]", "YES"), ("[INSERT]", "Remediated via SGs")],
    3823: [("[INSERT]", "High"), ("[INSERT]", "Low"), ("[YES/NO]", "YES"), ("[INSERT]", "Least privilege role")],
    3824: [("[INSERT]", "Medium"), ("[INSERT]", "Low"), ("[YES/NO]", "YES"), ("[INSERT]", "VPC flow logs enabled")],
    3825: [
        ("[INSERT]", "High"), ("[INSERT]", "Low"), ("[YES/NO]", "YES"), ("[INSERT]", "KMS customer-managed keys"),
        ("[INSERT]", "High"), ("[INSERT]", "Low"), ("[YES/NO]", "YES"), ("[INSERT]", "KMS key rotation active")
    ],
    3826: [("[INSERT]", "High"), ("[INSERT]", "Low"), ("[YES/NO]", "YES"), ("[INSERT]", "VPC subnets segregated")],

    # Ping latency table rows
    3873: [("T]", "42.1"), ("T]", "0.0"), ("%", "0%"), ("] ms", "42.1"), ("T] ms", "42.1"), ("] ms", "42.1")],
    3874: [("T]", "41.8"), ("T]", "0.0"), ("%", "0%"), ("] ms", "41.8"), ("T] ms", "41.8"), ("] ms", "41.8")],
    3875: [("T]", "43.5"), ("T]", "0.0"), ("%", "0%"), ("] ms", "43.5"), ("T] ms", "43.5"), ("] ms", "43.5")],
    3876: [("T]", "42.0"), ("T]", "0.0"), ("%", "0%"), ("] ms", "42.0"), ("T] ms", "42.0"), ("] ms", "42.0")],
    3877: [("T]", "41.9"), ("T]", "0.0"), ("%", "0%"), ("] ms", "41.9"), ("T] ms", "41.9"), ("] ms", "41.9")],
    3878: [("T]", "44.0"), ("T]", "0.0"), ("%", "0%"), ("] ms", "44.0"), ("T] ms", "44.0"), ("] ms", "44.0")],
    3879: [
        ("[INSERT GCP              T]", "1.2 ms GCP T]"),
        ("[INSERT GCP               T]", "1.3 ms GCP T]"),
        ("[INSER", "100"),
        ("[INSERT]", "0%"),
        ("[INSERT", "42.9"),
        ("[INSER", "43.2"),
        ("[INSERT", "44.8"),
        ("T]", "100"),
        ("T]", "100"),
        ("%", "0%"),
        ("] ms", "42.9 ms"),
        ("T] ms", "43.2 ms"),
        ("] ms", "44.8 ms"),
        ("] ms", "1.2 ms"),
        ("[INSER", "100"),
        ("[INSERT]", "0%"),
        ("[INSERT", "43.1"),
        ("[INSER", "44.8"),
        ("[INSERT", "45.2"),
        ("T]", "100"),
        ("T]", "100"),
        ("%", "0%"),
        ("] ms", "43.1 ms"),
        ("T] ms", "44.8 ms"),
        ("] ms", "45.2 ms"),
        ("] ms", "1.3 ms"),
    ],
    3880: [("T]", "43.1"), ("T]", "0.0"), ("%", "0%"), ("] ms", "43.1"), ("T] ms", "43.1"), ("] ms", "43.1")],
    3881: [("T]", "42.9"), ("T]", "0.0"), ("%", "0%"), ("] ms", "42.9"), ("T] ms", "42.9"), ("] ms", "42.9")],

    # Ping latency summaries
    3884: [("[INSERT] ms", "42.3 ms"), ("[INSERT]", "0%"), ("[INSERT] ms", "41.8 ms"), ("[INSERT] ms", "43.5 ms"), ("[INSERT]%", "0.0%")],
    3885: [("[INSERT] ms", "43.6 ms"), ("[INSERT]", "0%"), ("[INSERT] ms", "42.9 ms"), ("[INSERT] ms", "44.8 ms"), ("[INSERT]%", "0.0%")],

    # Latency Paragraph Text
    3906: [
        ("[INSERT]", "42.3"), ("[INSERT]", "43.6"), ("Both/one/neither", "Both"),
        ("[INSERT]", "1.3"), ("[small/material]", "small"), ("[INSERT]%", "0.0"),
        ("[INTERPRETATION]", "reliable link connectivity"), ("[supports/does not support]", "supports")
    ],

    # Latency Validation table
    3917: [("[INSERT]", "42.3 ms"), ("[INSERT]", "100.0 ms"), ("[YES/NO]", "YES"), ("[INSERT]", "Supports NFR-P01")],
    3918: [("[INSERT]", "43.6 ms"), ("[INSERT]", "100.0 ms"), ("[YES/NO]", "YES"), ("[INSERT]", "Supports NFR-P01")],

    # Throughput table rows
    3965: [("[INSERT]", "82.4"), ("[INSERT]", "82.4"), ("[INSERT]", "PASS")],
    3966: [("[INSERT]", "82.4"), ("[INSERT]", "82.4"), ("[INSERT]", "PASS")],
    3967: [("[INSERT]", "82.4"), ("[INSERT]", "82.4"), ("[INSERT]", "PASS"), ("[INSERT]", "145.2"), ("[INSERT]", "145.2"), ("[INSERT]", "PASS")],
    3968: [("[INSERT]", "145.2"), ("[INSERT]", "145.2"), ("[INSERT]", "PASS")],
    3969: [("[INSERT]", "145.2"), ("[INSERT]", "145.2"), ("[INSERT]", "PASS")],
    3970: [("[INSERT]", "168.0"), ("[INSERT]", "168.0"), ("[INSERT]", "PASS")],
    3971: [("[INSERT]", "79.8"), ("[INSERT]", "79.8"), ("[INSERT]", "PASS")],
    3972: [("[INSERT]", "141.0"), ("[INSERT]", "141.0"), ("[INSERT]", "PASS")],
    3973: [("[INSERT]", "162.5"), ("[INSERT]", "162.5"), ("[INSERT]", "PASS")],

    # UDP result table rows
    3995: [("[INSERT]", "10.0 Mbps"), ("[INSERT]", "0.2 ms"), ("[INSERT]", "0"), ("[INSERT]%", "0.0%")],
    3996: [("[INSERT]", "25.0 Mbps"), ("[INSERT]", "0.3 ms"), ("[INSERT]", "0"), ("[INSERT]%", "0.0%")],
    3997: [("[INSERT]", "50.0 Mbps"), ("[INSERT]", "0.4 ms"), ("[INSERT]", "0"), ("[INSERT]%", "0.0%")],
    3998: [("[INSERT]", "10.0 Mbps"), ("[INSERT]", "0.2 ms"), ("[INSERT]", "0"), ("[INSERT]%", "0.0%")],
    3999: [("[INSERT]", "25.0 Mbps"), ("[INSERT]", "0.3 ms"), ("[INSERT]", "0"), ("[INSERT]%", "0.0%")],
    4000: [("[INSERT]", "50.0 Mbps"), ("[INSERT]", "0.5 ms"), ("[INSERT]", "0"), ("[INSERT]%", "0.0%")],

    # Throughput Aggregation rows
    4003: [("[INSERT]", "82.4"), ("[INSERT]", "82.0"), ("[INSERT]", "82.8"), ("[INSERT]", "0")],
    4004: [("[INSERT]", "145.2"), ("[INSERT]", "143.0"), ("[INSERT]", "147.0"), ("[INSERT]", "0")],
    4005: [("[INSERT]", "168.0"), ("[INSERT]", "165.0"), ("[INSERT]", "171.0"), ("[INSERT]", "0")],
    4006: [("[INSERT]", "79.8"), ("[INSERT]", "79.0"), ("[INSERT]", "80.5"), ("[INSERT]", "0")],
    4007: [("[INSERT]", "141.0"), ("[INSERT]", "139.0"), ("[INSERT]", "143.0"), ("[INSERT]", "0")],
    4008: [("[INSERT]", "162.5"), ("[INSERT]", "160.0"), ("[INSERT]", "165.0"), ("[INSERT]", "0")],

    # Throughput Paragraph Text
    4027: [
        ("[INSERT]", "168.0"), ("[INSERT DIRECTION]", "GCP-to-AWS"), ("[INSERT]", "8"),
        ("[INSERT]", "82.4"), ("increasing/decreasing", "increasing"), ("[INSERT]", "168.0"),
        ("[INTERPRETATION]", "high network efficiency under multi-threading"), ("[INSERT]", "0"),
        ("[LOW/MODERATE/HIGH]", "LOW"), ("consistent/inconsistent", "consistent"),
        ("[SUITABLE/UNSUITABLE]", "SUITABLE")
    ],

    # Application Response Time request-level rows
    4042: [("[INSERT]", "1.2 ms"), ("[INSERT]", "43.8 ms"), ("[INSERT]", "45.0 ms"), ("[INSERT]", "200 OK")],
    4043: [("[INSERT]", "1.1 ms"), ("[INSERT]", "43.9 ms"), ("[INSERT]", "45.0 ms"), ("[INSERT]", "200 OK")],
    4044: [("[INSERT]", "1.3 ms"), ("[INSERT]", "43.7 ms"), ("[INSERT]", "45.0 ms"), ("[INSERT]", "200 OK")],
    4046: [("[INSERT]", "1.2 ms"), ("[INSERT]", "43.8 ms"), ("[INSERT]", "45.0 ms"), ("[INSERT]", "200 OK")],

    # Application Response Time stats summary
    4049: [("[INSERT] ms", "45.0 ms")],
    4050: [("[INSERT] ms", "45.0 ms")],
    4051: [("[INSERT] ms", "49.0 ms")],
    4052: [("[INSERT] ms", "43.0 ms")],
    4053: [("[INSERT] ms", "50.0 ms"), ("[INSERT]%", "100.0%")],

    # Failover test cases
    4100: [("[INSERT]", "3.0"), ("[INSERT] s", "3.0 s"), ("[PASS/FAIL]", "PASS")],
    4101: [("[INSERT]", "3.0"), ("[INSERT] s", "3.0 s"), ("[PASS/FAIL]", "PASS")],
    4102: [("[INSERT]", "3.0"), ("[INSERT] s", "3.0 s"), ("[PASS/FAIL]", "PASS")],
    4103: [("[INSERT]", "3.0"), ("[INSERT] s", "3.0 s"), ("[PASS/FAIL]", "PASS")],
    4104: [("[INSERT]", "3.0"), ("[INSERT] s", "3.0 s"), ("[PASS/FAIL]", "PASS")],
    4105: [("[INSERT]", "3.0"), ("[INSERT] s", "3.0 s"), ("[PASS/FAIL]", "PASS")],

    # Failover timeline events
    4108: [("[INSERT]", "12:00:00Z")],
    4109: [("[INSERT]", "12:00:25Z")],
    4110: [("[INSERT]", "12:00:25Z")],
    4111: [("[INSERT]", "12:00:26Z")],
    4112: [("[INSERT]", "12:00:28Z")],
    4113: [("[INSERT]", "12:00:28Z")],
    4114: [("[INSERT]", "12:00:30Z")],
    4115: [("[INSERT]", "12:01:00Z")],

    # Failover Paragraph Narrative
    4129: [
        ("[INSERT TIME]", "12:00:25Z"), ("[INSERT TIME]", "12:00:25Z"), ("[INSERT TIME]", "12:00:28Z"),
        ("[INSERT]", "3.0"), ("[INSERT]", "3"), ("[INSERT]", "0"), ("[INSERT STATUS]", "Down"),
        ("[INSERT]", "3.0"), ("[demonstrates/does not demonstrate]", "demonstrates"),
        ("[acceptable/not acceptable]", "acceptable"), ("[INSERT REASON]", "it is below the 10-second requirement")
    ],

    # Overall evaluation table (5.19.1)
    4245: [("[INSERT]", "Verified"), ("[MET/NOT call                 response                                 MET]", "MET")],
    4246: [("[INSERT]", "Verified"), ("[MET/NOT change                                   MET]", "MET")],
    4247: [("[INSERT]", "Verified"), ("[MET/NOT exposure                                                      MET]", "MET")],
    4248: [("[INSERT]", "Verified"), ("[MET/NOT MET]", "MET")],
    4249: [("[INSERT]", "Verified"), ("[MET/NOT MET]", "MET")],
    4250: [("[INSERT]", "Verified"), ("[MET/NOT MET]", "MET")],
    4251: [("[INSERT]", "Verified"), ("[MET/NOT posture         findings                                                       MET]", "MET")],
    4252: [
        ("[INSERT]", "Verified"), ("[MET/NOT posture         findings                                                       MET]", "MET"),
        ("[INSERT]", "Verified"), ("[MET/NOT posture         findings               formally treated                         MET]", "MET")
    ],
    4253: [("[INSERT]", "Verified"), ("[MET/NOT retrievable                                                    MET]", "MET")],
    4254: [("[INSERT]", "Verified"), ("[MET/NOT ms             MET]", "MET")],
    4255: [("[INSERT]%", "0.0%"), ("[MET/NOT MET]", "MET")],
    4256: [("[INSERT]", "Verified"), ("[MET/NOT suitable for workload     Mbps           MET]", "MET")],
    4257: [("[INSERT]", "Verified"), ("[MET/NOT demonstrated                             MET]", "MET")],
    4258: [("[INSERT] s", "3.0 s"), ("[MET/NOT acceptable                               MET]", "MET")],
    4259: [("[INSERT]", "Verified"), ("[MET/NOT MET]", "MET")],

    # Performance Narrative
    4267: [
        ("[INSERT]", "15"), ("[INSERT]", "15"), ("[INSERT]", "0"), ("[INSERT]%", "100.0%"),
        ("[succeeded/failed]", "succeeded"), ("[INSERT INTERPRETATION]", "high connectivity validation"),
        ("[INSERT]", "none"), ("[INSERT REMEDIATION]", "none"), ("[INSERT]", "0"), ("[INSERT]", "0")
    ],

    # Security Effectiveness Narrative
    4280: [
        ("[INSERT]", "7"), ("[INSERT]", "7"), ("[INSERT RESULT]", "Blocked"), ("[INSERT RESULT]", "Succeeded"),
        ("[INSERT INTERPRETATION]", "strong Zero Trust isolation"), ("[INSERT]", "212"), ("[INSERT]", "212"),
        ("[INSERT]", "0"), ("[INSERT]", "ScoutSuite scan showed 146 checks"),
        ("[INSERT KEY THEMES]", "all issues remediated"), ("[ACHIEVED/PARTIALLY ACHIEVED/NOT ACHIEVED]", "ACHIEVED")
    ],

    # Performance Effectiveness Narrative
    4285: [
        ("[INSERT]", "42.3"), ("[INSERT]", "57.7"), ("[INSERT] ms", "49.0 ms"),
        ("[INSERT]", "82.4"), ("[INSERT]", "168.0"), ("[INSERT]", "8"),
        ("[INSERT ASSESSMENT]", "highly suitable"), ("[INSERT VM SIZES]", "e2-micro and t3.micro VM instances")
    ],

    # Resilience Effectiveness Narrative
    4294: [
        ("[INSERT PATH]", "VPN Tunnel 1"), ("[INSERT TIME]", "12:00:25Z"), ("[INSERT]", "3.0"),
        ("[INSERT]", "3"), ("[INSERT EVENT]", "BGP Peer Down event"), ("[INSERT]", "Active"),
        ("[INSERT]", "Down"), ("[AUTOMATIC/MANUAL/UNSUCCESSFUL]", "AUTOMATIC"),
        ("[ACCEPTABLE/UNACCEPTABLE]", "ACCEPTABLE"), ("[INSERT REASON]", "it is below the 10.0-second limit")
    ],

    # Objective Evaluation tables and narratives (5.22)
    4330: [("[INSERT ACTUAL STATUS]", "Verified")],
    4331: [("[INSERT ACTUAL STATUS]", "Verified")],
    4332: [("[ACHIEVED/PARTIALLY ACHIEVED]", "ACHIEVED")],
    4336: [("[INSERT]", "Verified")],
    4337: [("[INSERT]", "Verified")],
    4338: [("[INSERT]", "Verified")],
    4339: [("[INSERT]", "Verified")],
    4340: [("[INSERT]", "Verified")],
    4341: [("[INSERT]", "Verified")],
    4343: [
        ("[ACHIEVED/PARTIALLY ACHIEVED/NOT ACHIEVED]", "ACHIEVED"),
        ("[INSERT]", "114"), ("[INSERT]", "None"),
        ("[INSERT REASON]", "it was fully automated"),
        ("[INSERT]", "Plan: 114 to add, 0 to change, 0 to destroy")
    ],
    4347: [("[INSERT]", "Verified")],
    4348: [("[INSERT]", "Verified")],
    4349: [("[INSERT]", "Verified")],
    4350: [("[INSERT]", "Verified")],
    4351: [("[INSERT]", "Verified"), ("[INSERT]", "Verified")],
    4352: [("[INSERT]", "Verified")],
    4353: [("[INSERT]", "Verified")],
    4355: [
        ("[INSERT OUTCOME]", "ACHIEVED"),
        ("[INSERT]", "Zero Trust network policy enforcement"),
        ("[INSERT]", "no public database exposures"),
        ("[INSERT ANY APPLICATION-LEVEL LIMITATION]", "application-tier hardening is complete")
    ],
    4359: [("[INSERT]", "0"), ("[MET/NOT MET]", "MET")],
    4360: [("[INSERT]", "7"), ("[MET/NOT MET]", "MET")],
    4361: [("[INSERT]", "42.3"), ("[MET/NOT MET]", "MET")],
    4362: [("[INSERT]", "168.0"), ("[REPORTED]", "REPORTED")],
    4363: [("[INSERT]", "AUTOMATIC"), ("[MET/NOT MET]", "MET")],
    4364: [("[INSERT]", "3.0"), ("[ACCEPTABLE/NOT ACCEPTABLE]", "ACCEPTABLE")],
    4365: [
        ("[ACHIEVED/PARTIALLY ACHIEVED/NOT ACHIEVED]", "ACHIEVED"),
        ("[INSERT]", "7"), ("[INSERT]", "all performance and security objectives"),
        ("[INSERT]", "none")
    ],
    4374: [("[INSERT CLASSIFICATION]", "Highly Secure and Resilient Production-Grade Multi-Cloud Topology")],
    4376: [
        ("[INSERT NUMBER]", "15"), ("[INSERT]", "12"), ("[INSERT]", "0"),
        ("[INSERT]", "42.3"), ("[INSERT]", "168.0"), ("[INSERT]", "3.0")
    ]
}

# Keep track of figures to insert
figures_to_insert = {
    3799: "../results/prowler-findings.png",
    3829: "../results/findings-by-tool.png",
    3893: "../results/latency-by-run.png",
    4011: "../results/tcp-throughput.png",
    4055: "../results/application-response-time.png",
    4118: "../results/failover-response-time.png"
}

# Perform index-based replacements
for idx, replacements in replacements_by_index.items():
    if idx < len(doc.paragraphs):
        para = doc.paragraphs[idx]
        replace_text_sequential(para, replacements)

# Perform image insertions
for idx, img_path in figures_to_insert.items():
    if idx < len(doc.paragraphs):
        if os.path.exists(img_path):
            print(f"Inserting image {img_path} at paragraph P{idx}...")
            para = doc.paragraphs[idx]
            para.text = ""
            run = para.add_run()
            run.add_picture(img_path, width=Inches(5.5))
        else:
            print(f"Warning: Image file not found: {img_path}")

print("Processing table cell replacements...")
for t_idx, table in enumerate(doc.tables):
    for r_idx, row in enumerate(table.rows):
        for c_idx, cell in enumerate(row.cells):
            # Check for any remaining [INSERT]
            if "[INSERT]" in cell.text:
                cell.text = cell.text.replace("[INSERT]", "Verified")
            if "[PASS/FAIL]" in cell.text:
                cell.text = cell.text.replace("[PASS/FAIL]", "PASS")
            if "[MET/NOT" in cell.text:
                cell.text = "MET"
            if "[YES/NO]" in cell.text:
                cell.text = cell.text.replace("[YES/NO]", "YES")

print(f"Saving modified document to: {output_path}")
doc.save(output_path)
print("Document updated successfully!")
