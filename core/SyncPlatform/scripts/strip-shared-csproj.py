import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
pattern = re.compile(
    r'\s*<Content Include="[^"]*appsettings\.Shared[^"]*"[^>]*>'
    r'(?:\s*<CopyToOutputDirectory>[^<]*</CopyToOutputDirectory>\s*)?'
    r'</Content>\s*',
    re.MULTILINE,
)
pattern2 = re.compile(r'\s*<Content Include="[^"]*appsettings\.Shared[^"]*"[^/]*/>\s*', re.MULTILINE)

for csproj in root.rglob("*.csproj"):
    text = csproj.read_text(encoding="utf-8")
    new = pattern.sub("\n", text)
    new = pattern2.sub("\n", new)
    if new != text:
        csproj.write_text(new, encoding="utf-8")
        print(f"updated {csproj.relative_to(root)}")
