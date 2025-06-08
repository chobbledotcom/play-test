#\!/bin/bash

echo "=== HARDCODED STRINGS IN VIEWS ==="
echo "1. Button/Link text:"
grep -r --include="*.erb" -E '(button_to < /dev/null | link_to|submit).*"[^"]{3,}"' app/views/ | grep -v 'I18n\.t' | grep -v 't(' | grep -v 'data:' | grep -v 'method:' | grep -v 'class:' | sort -u

echo -e "\n2. Labels:"
grep -r --include="*.erb" -E 'label.*"[^"]{3,}"' app/views/ | grep -v 'I18n\.t' | grep -v 't(' | grep -v 'for=' | sort -u

echo -e "\n3. Plain text between tags:"
grep -r --include="*.erb" -E '<(h[1-6]|p|li|strong|em|td|th)>[^<]*[A-Za-z]{3,}' app/views/ | grep -v '<%' | grep -v 'I18n\.t' | grep -v 't(' | sort -u

echo -e "\n=== HARDCODED STRINGS IN CONTROLLERS ==="
echo "4. Flash messages:"
grep -r --include="*.rb" -E 'flash\[:[a-z]+\].*=.*"' app/controllers/ | grep -v 'I18n\.t' | grep -v 't(' | sort -u

echo -e "\n5. Validation messages:"
grep -r --include="*.rb" -E '(errors\.add|validates.*message:).*"' app/models/ | grep -v 'I18n\.t' | grep -v 't(' | sort -u

echo -e "\n=== HARDCODED STRINGS IN HELPERS ==="
echo "6. Helper methods:"
grep -r --include="*.rb" -E '"[^"]{3,}"' app/helpers/ | grep -v 'I18n\.t' | grep -v 't(' | grep -v 'class:' | sort -u
