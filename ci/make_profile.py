"""App Store Connect API 로 App Store 배포용 프로비저닝 프로파일을 새로 만들어 설치합니다.

자동 서명은 개발용 프로파일(등록된 기기 필요)부터 찾다가 실패하므로, 빌드할 때마다
배포 인증서(CERT_SERIAL)와 번들 ID 로 배포용 프로파일을 만들고 이름(PROFILE_NAME)으로 씁니다.
환경 변수: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH, BUNDLE_ID, CERT_SERIAL, PROFILE_NAME
"""
import base64
import json
import os
import pathlib
import time
import urllib.error
import urllib.request

import jwt

API = "https://api.appstoreconnect.apple.com/v1"


def token() -> str:
    key = pathlib.Path(os.environ["ASC_KEY_PATH"]).read_text()
    now = int(time.time())
    return jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"},
                      key, algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"})


def call(method: str, path: str, body: dict | None = None) -> dict:
    req = urllib.request.Request(API + path, method=method, data=json.dumps(body).encode() if body else None,
                                 headers={"Authorization": "Bearer " + token(), "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raise SystemExit(f"{method} {path} -> {e.code}: {e.read().decode()[:800]}")


def main() -> None:
    bundle_id = os.environ["BUNDLE_ID"]
    name = os.environ["PROFILE_NAME"]
    serial = os.environ["CERT_SERIAL"].upper().lstrip("0")

    found = call("GET", f"/bundleIds?filter[identifier]={bundle_id}&limit=50")["data"]
    found = [b for b in found if b["attributes"]["identifier"] == bundle_id]
    if found:
        bid = found[0]["id"]
    else:
        bid = call("POST", "/bundleIds", {"data": {"type": "bundleIds", "attributes": {
            "identifier": bundle_id, "name": "Veriscope", "platform": "IOS"}}})["data"]["id"]
        print("번들 ID 등록:", bundle_id)

    certs = call("GET", "/certificates?limit=200")["data"]
    cert = [c for c in certs if c["attributes"].get("serialNumber", "").upper().lstrip("0") == serial]
    if not cert:
        raise SystemExit("배포 인증서를 App Store Connect 에서 찾지 못했습니다 (serial " + serial + ")")
    print("인증서:", cert[0]["attributes"].get("name"), cert[0]["attributes"].get("certificateType"))

    for p in call("GET", f"/profiles?filter[name]={urllib.request.quote(name)}&limit=50")["data"]:
        call("DELETE", f"/profiles/{p['id']}")      # 이전 빌드가 만든 같은 이름의 프로파일

    prof = call("POST", "/profiles", {"data": {
        "type": "profiles",
        "attributes": {"name": name, "profileType": "IOS_APP_STORE"},
        "relationships": {
            "bundleId": {"data": {"type": "bundleIds", "id": bid}},
            "certificates": {"data": [{"type": "certificates", "id": cert[0]["id"]}]},
        }}})["data"]
    out = pathlib.Path.home() / "Library/MobileDevice/Provisioning Profiles" / (prof["attributes"]["uuid"] + ".mobileprovision")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(base64.b64decode(prof["attributes"]["profileContent"]))
    print("프로파일 설치:", name, prof["attributes"]["uuid"])


if __name__ == "__main__":
    main()
