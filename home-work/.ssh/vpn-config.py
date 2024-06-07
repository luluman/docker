#!/usr/bin/env python3

import requests
import yaml
import os, sys

script_dir = os.path.dirname(os.path.abspath(__file__))
config_file = "clash_config.yaml"
clash_config_path = f"/opt/{config_file}"


def get_server_config(url):
    # Step 1: Download the file from the URL
    response = requests.get(url.strip())
    yaml_content = response.text

    # Step 2: Read the file and modify the specified field
    data = yaml.safe_load(yaml_content)

    # Find the proxy-groups and modify the '节点选择' group
    for group in data["proxy-groups"]:
        if group["name"] == "🚀 节点选择":
            group["proxies"] = [
                "🇸🇬 新加坡节点",
                "🇭🇰 香港节点",
                "🇹🇼 台湾节点",
                "🇺🇲 美国节点",
                "🇯🇵 日本节点",
                "✈️ 手动切换",
                "♻️ 自动选择",
                "🔯 故障转移",
                "🎯 全球直连",
            ]

    # Step 3: Save the modified content back to a YAML file
    with open(clash_config_path, "w", encoding="utf-8") as file:
        yaml.dump(data, file, allow_unicode=True)

    os.chmod(clash_config_path, 0o666)


if __name__ == "__main__":
    get_server_config(sys.argv[1])
    print(f"clash -f {clash_config_path}", end="")
