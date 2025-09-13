#!/bin/bash

# 1. Check that the SEO pages are accessible
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/)
if [ "$response" -ne 200 ]; then
  echo "SEO test failed. Home page not accessible."
  exit 1
fi

response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/about)
if [ "$response" -ne 200 ]; then
  echo "SEO test failed. About page not accessible."
  exit 1
fi

response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/contact)
if [ "$response" -ne 200 ]; then
  echo "SEO test failed. Contact page not accessible."
  exit 1
fi

# 2. Test meta tags in page source
response=$(curl -s http://localhost:3000/)
if ! echo "$response" | grep -q "My Next.js App"; then
  echo "SEO test failed. Page should contain app title."
  exit 1
fi

# 3. Test about page content
response=$(curl -s http://localhost:3000/about)
if ! echo "$response" | grep -q "About Us"; then
  echo "SEO test failed. About page should contain 'About Us'."
  exit 1
fi

# 4. Test contact page content
response=$(curl -s http://localhost:3000/contact)
if ! echo "$response" | grep -q "Contact Us"; then
  echo "SEO test failed. Contact page should contain 'Contact Us'."
  exit 1
fi

# In a real test, you would need to check the actual HTML source
# to verify that meta tags are properly included in the head section.

echo "SEO test passed!"
exit 0
