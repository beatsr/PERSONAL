const { exec } = require("child_process");

module.exports = async (params) => {
  const scripts = [
    { command: "_tools/__formatting.sh", name: "Format" },
    { command: "_tools/__rebuild_index.sh", name: "Rebuild Index" },
    { command: "_tools/__sync.sh", name: "Sync" },
    { command: "_tools/__upload_attachments.sh", name: "Upload Attachments" },
  ];

  // Let user select a script
  const choices = scripts.map((script) => script.name);
  const selectedName = await params.quickAddApi.suggester(choices, choices);
  if (!selectedName) {
    new Notice("No script selected", 3000);
    return;
  }
  const selectedScript = scripts.find((script) => script.name === selectedName);

  // Build AppleScript command to launch Terminal and execute the script
  const vaultPath = params.app.vault.adapter.basePath;
  const terminalCommand = `osascript -e 'tell application "Terminal"' -e 'activate' -e 'do script "cd \\"${vaultPath}\\" && bash \\"${selectedScript.command}\\" && exit"' -e 'end tell'`;

  // Execute the command
  exec(terminalCommand, (error, stdout, stderr) => {
    if (error) {
      console.error(`Execution error: ${error}`);
      new Notice(
        `Failed to launch ${selectedScript.name}: ${error.message}`,
        5000,
      );
    }
  });
};
