#!/usr/bin/env python3
"""
Rename Neovim plugin template with typer CLI.

What this script does:
1. Renames lua/myplugin → lua/my_plugin
2. Updates all text: myplugin → my_plugin, MyPlugin → MyPlugin, your-username → username
3. Sets git remote origin (if git-url provided)
"""
import os
import shutil
import subprocess
from pathlib import Path
from typing import Optional

import typer


def to_snake_case(name: str) -> str:
    """my-plugin → my_plugin"""
    return name.replace('-', '_').lower()


def to_camel_case(name: str) -> str:
    """my-plugin → MyPlugin"""
    return ''.join(word.capitalize() for word in name.replace('-', '_').split('_'))


def main(
    plugin_name: str = typer.Argument(..., help="Plugin name (e.g., my-awesome-plugin)"),
    username: str = typer.Argument(..., help="GitHub username"),
    git_url: Optional[str] = typer.Argument(None, help="Git repository URL (optional)")
) -> None:
    """Rename Neovim plugin template and update all references."""

    plugin_snake = to_snake_case(plugin_name)
    plugin_camel = to_camel_case(plugin_name)

    typer.echo(f"Renaming: {plugin_name} ({plugin_snake}, {plugin_camel}) for {username}")

    # Text replacements to make throughout files
    replacements = {
        'myplugin': plugin_snake,
        'MyPlugin': plugin_camel,
        'your-username': username,
        'your-plugin-name': plugin_name,
        'YourPluginName': plugin_camel,
    }

    # 1. Rename directory: lua/myplugin → lua/plugin_snake
    old_dir = Path('lua/myplugin')
    new_dir = Path(f'lua/{plugin_snake}')
    if old_dir.exists():
        shutil.move(str(old_dir), str(new_dir))
        typer.echo(f"✓ Renamed {old_dir} → {new_dir}", color=typer.colors.GREEN)

    # 2. Update file contents
    files_to_update = [
        f'lua/{plugin_snake}/init.lua',
        f'lua/{plugin_snake}/config.lua',
        f'lua/{plugin_snake}/commands.lua',
        'lazy.lua',
        'README.md'
    ]

    for file_path in files_to_update:
        path = Path(file_path)
        if path.exists():
            content = path.read_text()
            for old, new in replacements.items():
                content = content.replace(old, new)
            path.write_text(content)
            typer.echo(f"✓ Updated {file_path}", color=typer.colors.GREEN)

    # 3. Set git remote origin
    if git_url:
        try:
            subprocess.run(['git', 'remote', 'set-url', 'origin', git_url], check=True)
            typer.echo(f"✓ Set git remote: {git_url}", color=typer.colors.GREEN)
        except Exception:
            typer.echo("! Could not set git remote", color=typer.colors.YELLOW)

        # 4. Update the Lazy Spec Repo
        repo_name = os.path.basename(git_url)
        suffix = "nvim"
        if repo_name.endswith(suffix):
            repo_stripped = repo_name[:-len(suffix)]  # Remove ".nvim" suffix
            lazy_path = Path('lazy.lua')
            if lazy_path.exists():
                lazy_content = lazy_path.read_text()
                lazy_content = lazy_content.replace("/nvim-plugin-template", f"/{repo_stripped}")
                lazy_path.write_text(lazy_content)
                typer.echo("✓ Updated lazy.lua repo reference", color=typer.colors.GREEN)






    typer.echo(f"\n🎉 Done! Test with: require('{plugin_snake}').setup()", color=typer.colors.CYAN)


if __name__ == "__main__":
    typer.run(main)
