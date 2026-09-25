import InfomaniakRichHTMLEditor
import SwiftUI
import WebKit

struct EditorScreen: View {
    @Binding var html: String

    @StateObject private var textAttributes = TextAttributes()
    @State private var editorView: RichHTMLEditorView?
    @State private var showLinkAlert = false
    @State private var linkText = ""

    private let accent = Color.buttonBackground

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("editor.content.title")
                .font(.headline)

            VStack(spacing: 0) {
                formattingToolbar

                Divider()

                RichHTMLEditor(
                    html: $html,
                    textAttributes: textAttributes
                )
                .editorScrollable(true)
                .onEditorLoaded { view in
                    editorView = view
                    installSelectionTracking(in: view)
                }
                .frame(height: 260)
                .padding(12)
            }
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.borderColor)
            }
        }
        .alert("editor.link.title", isPresented: $showLinkAlert) {
            TextField("editor.link.placeholder", text: $linkText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button("editor.action.cancel", role: .cancel) {
                linkText = ""
            }

            Button("editor.action.add") {
                addLink()
            }
        } message: {
            Text("editor.link.message")
        }
    }

    private var formattingToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                toolButton(
                    String(localized: "editor.format.bold"),
                    symbol: "bold",
                    active: textAttributes.hasBold
                ) {
                    runCommand("bold")
                }

                toolButton(
                    String(localized: "editor.format.italic"),
                    symbol: "italic",
                    active: textAttributes.hasItalic
                ) {
                    runCommand("italic")
                }

                toolButton(
                    String(localized: "editor.format.underline"),
                    symbol: "underline",
                    active: textAttributes.hasUnderline
                ) {
                    runCommand("underline")
                }

                separator

                headingButton("H1") {
                    runCommand("formatBlock", value: "H1")
                }

                headingButton("H2") {
                    runCommand("formatBlock", value: "H2")
                }

                headingButton("H3") {
                    runCommand("formatBlock", value: "H3")
                }

                headingButton("P") {
                    runCommand("formatBlock", value: "P")
                }

                separator

                toolButton(
                    String(localized: "editor.format.bulletList"),
                    symbol: "list.bullet",
                    active: textAttributes.hasUnorderedList
                ) {
                    runCommand("insertUnorderedList")
                }

                toolButton(
                    String(localized: "editor.format.numberedList"),
                    symbol: "list.number",
                    active: textAttributes.hasOrderedList
                ) {
                    runCommand("insertOrderedList")
                }

                toolButton(
                    String(localized: "editor.format.link"),
                    symbol: "link",
                    active: textAttributes.hasLink
                ) {
                    linkText = ""
                    showLinkAlert = true
                }

                toolButton(
                    String(localized: "editor.format.clear"),
                    symbol: "textformat",
                    active: false
                ) {
                    runCommand("removeFormat")
                }

                separator

                toolButton(
                    String(localized: "editor.action.undo"),
                    symbol: "arrow.uturn.backward",
                    active: false
                ) {
                    runCommand("undo")
                }

                toolButton(
                    String(localized: "editor.action.redo"),
                    symbol: "arrow.uturn.forward",
                    active: false
                ) {
                    runCommand("redo")
                }
            }
            .padding(10)
        }
        .scrollDismissesKeyboard(.never)
    }

    private var separator: some View {
        Rectangle()
            .fill(Color.borderColor)
            .frame(width: 1, height: 24)
            .padding(.horizontal, 3)
    }

    private func toolButton(
        _ title: String,
        symbol: String,
        active: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 38, height: 38)
                .foregroundStyle(active ? Color.buttonText : accent)
                .background(
                    active
                        ? accent
                        : Color.surfaceBackground
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func headingButton(
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .frame(width: 38, height: 38)
                .foregroundStyle(accent)
                .background(Color.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            title == "P"
                ? String(localized: "editor.format.paragraph")
                : title
        )
    }

    // MARK: - Selection

    private func installSelectionTracking(in view: RichHTMLEditorView) {
        let script = """
        (() => {
            if (window.walknjoySelectionInstalled) return;

            const editor = document.querySelector('[contenteditable="true"]');
            if (!editor) return;

            window.walknjoySelectionInstalled = true;

            document.addEventListener('selectionchange', () => {
                const selection = window.getSelection();

                if (!selection || !selection.rangeCount || selection.isCollapsed) {
                    return;
                }

                const range = selection.getRangeAt(0);

                if (editor.contains(range.commonAncestorContainer)) {
                    window.walknjoySavedRange = range.cloneRange();
                }
            });

            editor.addEventListener('input', () => {
                window.walknjoySavedRange = null;
            });

            editor.addEventListener('pointerdown', () => {
                window.walknjoySavedRange = null;
            });
        })();
        """

        view.webView.evaluateJavaScript(script)
    }

    // MARK: - Formatting

    private func runCommand(_ command: String, value: String? = nil) {
        let allowedCommands: Set<String> = [
            "bold",
            "italic",
            "underline",
            "formatBlock",
            "insertUnorderedList",
            "insertOrderedList",
            "removeFormat",
            "undo",
            "redo"
        ]

        guard allowedCommands.contains(command) else { return }

        let arguments = [command, value ?? ""]

        guard
            let data = try? JSONSerialization.data(withJSONObject: arguments),
            let json = String(data: data, encoding: .utf8)
        else {
            return
        }

        let script = """
        (() => {
            const [command, value] = \(json);
            const selection = window.getSelection();
            const savedRange = window.walknjoySavedRange;

            if (savedRange && selection) {
                selection.removeAllRanges();
                selection.addRange(savedRange);
            }

            const result = document.execCommand(
                command,
                false,
                value || null
            );

            window.walknjoySavedRange = null;
            return result;
        })();
        """

        editorView?.webView.evaluateJavaScript(script)
    }

    // MARK: - Link

    private func addLink() {
        let address = linkText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard
            let url = URL(string: address),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host != nil,
            let data = try? JSONSerialization.data(
                withJSONObject: [url.absoluteString]
            ),
            let json = String(data: data, encoding: .utf8)
        else {
            return
        }

        let script = """
        (() => {
            const [url] = \(json);
            const selection = window.getSelection();
            const savedRange = window.walknjoySavedRange;

            if (!selection || !savedRange) return false;

            selection.removeAllRanges();
            selection.addRange(savedRange);

            const result = document.execCommand(
                'createLink',
                false,
                url
            );

            window.walknjoySavedRange = null;
            return result;
        })();
        """

        editorView?.webView.evaluateJavaScript(script)
        linkText = ""
    }
}
