# Neovim Plugin Template Justfile

# Show available commands
default:
    @just --list

# Rename the plugin and update all references
rename plugin_name username upstream_url="":
    uv run --with typer scripts/rename_plugin.py "{{plugin_name}}" "{{username}}" "{{upstream_url}}"

# Initialize a new plugin with name, username, and optional upstream URL
init plugin_name username upstream_url="":
    @echo "Initializing new plugin: {{plugin_name}}"
    @echo "Username: {{username}}"
    @if [ "{{upstream_url}}" != "" ]; then echo "Upstream URL: {{upstream_url}}"; fi
    uv run --with typer scripts/rename_plugin.py "{{plugin_name}}" "{{username}}" "{{upstream_url}}"
    @echo "Plugin initialization complete!"
    @echo "Next steps:"
    @echo "1. Review the generated files"
    @echo "2. Test the plugin: :MyPluginGreet"
    @echo "3. Start developing your features"

# Test the current plugin
test:
    @echo "Testing plugin..."
    @echo "Make sure to install the plugin in Neovim and run :MyPluginGreet"

# Clean up temporary files
clean:
    find . -name "*.pyc" -delete
    find . -name "__pycache__" -delete