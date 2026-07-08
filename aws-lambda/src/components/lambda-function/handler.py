import json

_counts = {}


def handler(event, context):
    widget = (event.get("pathParameters") or {}).get("id", "default")
    _counts[widget] = _counts.get(widget, 0) + 1
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"widget": widget, "count": _counts[widget]}),
    }
