# SPDX-License-Identifier: GPL-3.0-only
import os,json,urllib.request,hashlib
from pathlib import Path
repo=os.environ['GITHUB_REPOSITORY']
headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28'}
def api(url,method='GET',data=None,content='application/json'):
 h={**headers,'Content-Type':content}
 req=urllib.request.Request(url,data=data,headers=h,method=method)
 with urllib.request.urlopen(req,timeout=120) as response:return json.load(response)
uri='https://api.github.com/repos/'+repo+'/releases/tags/v0.1.0'
release=api(uri)
assert not release['draft']
files=sorted(Path('linux-artifacts').iterdir());expected=[]
for p in files:
 digest='sha256:'+hashlib.sha256(p.read_bytes()).hexdigest();expected.append((p.name,digest))
 existing=next((a for a in release['assets'] if a['name']==p.name),None)
 if existing:
  assert existing.get('digest')==digest and existing['size']==p.stat().st_size,p.name
 else:
  asset=api('https://uploads.github.com/repos/'+repo+'/releases/'+str(release['id'])+'/assets?name='+p.name,'POST',p.read_bytes(),'application/octet-stream')
  assert asset.get('digest')==digest,p.name
release=api(uri)
for name,digest in expected:assert next(a for a in release['assets'] if a['name']==name).get('digest')==digest
body=release['body']
if '## Linux x86_64' not in body:
 body+='\n\n## Linux x86_64\n\nDownload `EmberpvpLauncher-Linux-x86_64.flatpak`. This direct Flatpak bundle uses the KDE 6.10 runtime from Flathub and runs as a native C++/Qt application. The launcher itself is not listed on Flathub. Install it per user with `flatpak install --user ./EmberpvpLauncher-Linux-x86_64.flatpak`, then run `flatpak run org.emberpvp.EmberpvpLauncher`. Add the Flathub runtime remote first if it is not configured.\n\nThe build passed compatibility/unit tests, the 3D skin and appearance tests under a native Wayland compositor, and an installed-bundle native Wayland startup check in CI. Physical GPUs, Microsoft sign-in, and actual Minecraft gameplay still require interactive testing. ARM/32-bit bundles are not provided. Matching Linux source and `Linux-SHA256SUMS.txt` accompany the bundle.\n'
 api('https://api.github.com/repos/'+repo+'/releases/'+str(release['id']),'PATCH',json.dumps({'name':'Emberpvp Launcher 0.1.0 - Windows and Linux','body':body}).encode())
print(json.dumps({'published_linux_assets':expected,'release_url':release['html_url']},indent=2))
