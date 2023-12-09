from connexion import AsyncApp
import datetime
import subprocess
import endpoints
import json


def full_prove(body):
    proofs_fpath = f'proofs/{datetime.datetime.now()}/'
    subprocess.run(['mkdir', '-p', proofs_fpath])
    return endpoints.full_prove(body["values"], body["initialHash"],
                                proofs_fpath=proofs_fpath,
                                )

def home(body):
    with open('proofs/testfile.json', 'w+') as f:
        json.dump(body, f)
    return body, 200

app = AsyncApp(__name__)
app.add_api("openapi.yaml")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
