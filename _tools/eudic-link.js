module.exports = async (params) => {
  const { app } = params;

  // 获取当前活动的编辑器
  const activeLeaf = app.workspace.activeLeaf;
  if (!activeLeaf || !activeLeaf.view) {
    new Notice("请在编辑模式下使用此功能");
    return;
  }

  const editor = activeLeaf.view.editor;
  if (!editor) {
    new Notice("无法获取编辑器，请确保在编辑模式下");
    return;
  }

  // 获取选中的文本
  const selection = editor.getSelection();

  if (selection && selection.trim()) {
    // 对文本进行 URL 编码
    const encodedText = encodeURIComponent(selection.trim());

    // 创建 Eudic 链接格式
    const eudicLink = `[${selection}](eudic://dict/${encodedText})`;

    // 替换选中的文本
    editor.replaceSelection(eudicLink);

    new Notice(`已转换为 Eudic 链接: ${selection}`);
  } else {
    new Notice("请先选择要转换的文本");
  }
};
