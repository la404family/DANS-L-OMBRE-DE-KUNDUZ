import os
import re

def remove_comments(source):
    # Pattern to match:
    # 1. Single line comments: // ...
    # 2. Multi line comments: /* ... */
    # 3. Double quoted strings: "..."
    # 4. Single quoted strings: '...'
    # We want to keep strings and remove comments.
    
    # Using a replacer function:
    # If the match starts with " or ', it's a string -> keep it.
    # Otherwise it's a comment -> replace with empty string or space.
    
    pattern = re.compile(
        r'//.*?$|/\*.*?\*/|\'(?:\\.|[^\\\'])*\'|"(?:\\.|[^\\"])*"',
        re.DOTALL | re.MULTILINE
    )
    
    def replacer(match):
        s = match.group(0)
        if s.startswith('/'):
            # It's a comment
            return " "
        else:
            # It's a string, keep it
            return s
            
    return re.sub(pattern, replacer, source)

def cleanup_empty_lines(text):
    # Remove lines that contain only whitespace
    return re.sub(r'^\s*$\n', '', text, flags=re.MULTILINE)

def process_directory(root_dir):
    # Valid extensions for Arma 3 scripting
    extensions = ['.sqf', '.hpp', '.ext', '.cpp', '.h']
    
    print(f"Scanning directory: {root_dir}")
    
    for root, dirs, files in os.walk(root_dir):
        # Skip .git or other system folders if necessary
        if '.git' in root:
            continue
            
        for file in files:
            file_lower = file.lower()
            if any(file_lower.endswith(ext) for ext in extensions):
                file_path = os.path.join(root, file)
                
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        original_content = f.read()
                    
                    # 1. Remove comments
                    cleaned_content = remove_comments(original_content)
                    
                    # 2. Remove empty lines left behind
                    final_content = cleanup_empty_lines(cleaned_content)
                    
                    if original_content != final_content:
                        with open(file_path, 'w', encoding='utf-8') as f:
                            f.write(final_content)
                        print(f"Processed: {file}")
                    else:
                        pass # No changes needed
                        
                except Exception as e:
                    print(f"Error processing {file}: {e}")

if __name__ == "__main__":
    current_dir = os.getcwd()
    confirm = input(f"This will remove ALL comments from supported files in {current_dir}.\nAre you sure? (y/n): ")
    if confirm.lower() == 'y':
        process_directory(current_dir)
        print("Done.")
    else:
        print("Operation cancelled.")
