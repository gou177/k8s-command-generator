import os
import sys
from typing import Dict, List, Tuple, Union
import inquirer
import re
from blessed import Terminal

term = Terminal()

parts: Dict[str, Dict[str, List[str]]] = {}
spaceRegex = re.compile(r" +")
stringFormatEscapeRegex = re.compile(r"([\$%])\{([\w\d_-]+)\}")
newlineRegex = re.compile(r"\n\n+")

context: Dict[str, Union[str, List[str]]] = {
    "preflighterrors": "",
}
pipeline = ["netfilter", "cri", "kube-tools", "swap", "action", "cni", "join", "addons"]


def clearStr(data: str) -> str:
    data = spaceRegex.sub(" ", data)
    if data.startswith(" "):
        data = data[1:]
    if data.endswith(" "):
        data = data[:-1]
    return data


def getPartNameAndValue(part: str, defaultName: str = "") -> Tuple[str, str]:
    part = part.replace("\n", "").replace("#", "")

    if ":" in part:
        name, value = part.split(":", 1)
        return clearStr(name), clearStr(value)

    return defaultName, clearStr(part)


def loadFileParts(file: str):
    data = ""
    name = ""
    value = ""

    with open(file, "r") as f:
        for line in f.readlines():
            if line.startswith("#"):
                if data and name and value:
                    parts.setdefault(name, {}).setdefault(value, []).append(data)

                name, value = getPartNameAndValue(
                    line, defaultName=file.split(".", 1)[0]
                )
                data = ""
            line = stringFormatEscapeRegex.sub(r"\1{{\2}}", line)
            data += line

        if data and name and value:
            parts.setdefault(name, {}).setdefault(value, []).append(data)


def loadParts():
    for file in os.listdir("."):
        if not file.endswith(".bash"):
            continue
        loadFileParts(file)


def prompt(questions: List):
    answers = inquirer.prompt(questions)

    if not answers:
        sys.exit(1)
    context.update(answers)


def formatPart(part: str):
    contextValue = context.get(part, "")

    if isinstance(contextValue, str):
        template = "\n".join(parts.get(part, {}).get(contextValue, [])).format(
            **context
        )
        if template:
            template = (
                f"echo \"{'='*35}\n      {part}: {contextValue}\n{'='*35}\n\"\n"
                + template
            )
        return template

    data = ""
    for value in contextValue:
        template = "\n".join(parts.get(part, {}).get(value, []))

        if template:
            data += f"echo \"{'='*35}\n      {part}: {value}\n{'='*35}\n\"\n"

        data += template.format(**context)
        data += "\n\n"

    return data


loadParts()

prompt(
    [
        inquirer.List(
            "action",
            message="What do you want to do with k8s?",
            choices=["init", "join", "addons", "wipe"],
            carousel=True,
        )
    ]
)

if context["action"] in ["init", "join"]:
    prompt(
        [
            inquirer.List(
                "cri",
                "Install container runtime interface?",
                choices=["containerd", "no"],
                default="containerd",
            ),
            inquirer.List(
                "kube-tools",
                "Install kubeadm, kubelet, kubectl?",
                choices=["yes", "no"],
                default="yes",
            ),
            inquirer.List(
                "swap",
                "Swap?",
                choices=["yes", "no"],
                default="yes",
            ),
            inquirer.List(
                "netfilter",
                "Netfilter?",
                choices=["yes", "no"],
                default="yes",
            ),
        ]
    )
    if context["swap"] == "yes":
        context["preflighterrors"] = "Swap"

if context["action"] == "join":
    join_cmd = input(
        f"[{term.yellow}?{term.normal}] Join command:\n{term.blue}>{term.normal} "
    )

    while i := input(f"{term.blue}>{term.normal} "):
        join_cmd += i + "\n"

    context["join_cmd"] = join_cmd


elif context["action"] == "init":
    prompt([inquirer.List("cni", "Cni", parts["cni"].keys(), "flannel")])

    if context["cni"] == "calico":
        prompt([inquirer.Text("cidr", "cidr", "192.168.0.0/16")])
    else:
        prompt([inquirer.Text("cidr", "cidr", "10.244.0.0/16")])

if context["action"] in ["addons", "init"]:
    prompt(
        [
            inquirer.Checkbox(
                "addons", "Addons (space for select)", parts["addons"].keys()
            )
        ]
    )

cmd = ""
for action in pipeline:
    cmd += formatPart(action)
    cmd += "\n"

print("================================================")
print("     command")
print("================================================")
print()
print("bash << EOK8S")
print(newlineRegex.sub("\n\n", cmd).replace("$", "\\$"))
print("EOK8S")
