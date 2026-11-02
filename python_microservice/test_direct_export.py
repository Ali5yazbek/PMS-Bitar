from export_utils import generate_monthly_export
import sys

print("Testing generate_monthly_export...")
try:
    response = generate_monthly_export("2026-08")
    with open("direct_test_export.xlsx", "wb") as f:
        f.write(response.body)
    print("Success! File size:", len(response.body))
except Exception as e:
    import traceback
    traceback.print_exc()
