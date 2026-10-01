import os
import re

lib_dir = r"c:\CODEXXA_PROJECT\mantri_app\lib"

# Matches: ScaffoldMessenger.of(context).showSnackBar( ... SnackBar(content: Text( '...' )) ... );
pattern = re.compile(
    r"ScaffoldMessenger\.of\([^)]+\)\.showSnackBar\(\s*(?:const\s*)?SnackBar\(\s*content:\s*Text\(\s*(.*?)\s*\)(?:,\s*backgroundColor[^)]*)?\s*\)\s*\)(?:;)?",
    re.DOTALL
)

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    
    def replacer(match):
        text_arg = match.group(1)
        # Determine dialog type based on text content roughly
        lower_text = text_arg.lower()
        if 'error' in lower_text or 'fail' in lower_text or 'not ' in lower_text:
            dialog_type = "AppDialogs.showErrorDialog"
            return f"{dialog_type}(context, userMessage: {text_arg});"
        elif 'delete' in lower_text or 'remove' in lower_text:
            dialog_type = "AppDialogs.showWarningDialog"
            return f"AppDialogs.showWarningDialog(context, message: {text_arg});"
        else:
            return f"AppDialogs.showSuccessDialog(context, message: {text_arg});"

    new_content = pattern.sub(replacer, content)

    if new_content != original_content:
        # Check if AppDialogs is imported
        if "AppDialogs" in new_content and "app_dialogs.dart" not in new_content:
            # Add import after other imports
            import_statement = "import 'package:mantri_app/core/utils/app_dialogs.dart';\n"
            # Find the last import
            imports = list(re.finditer(r"^import\s+['\"].*?['\"];", new_content, re.MULTILINE))
            if imports:
                last_import = imports[-1]
                insert_pos = last_import.end() + 1
                new_content = new_content[:insert_pos] + import_statement + new_content[insert_pos:]
            else:
                new_content = import_statement + "\n" + new_content

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated: {filepath}")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

print("Done.")
