
#!/bin/bash
set -e
# Install Flutter if not present
if ! command -v flutter &> /dev/null
then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
  export PATH="$PATH:$(pwd)/flutter/bin"
fi
flutter pub get
flutter build web