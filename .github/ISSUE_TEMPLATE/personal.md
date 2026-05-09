---
name: Personal
about: Describe this issue template's purpose here.
title: ''
labels: ''
assignees: imhicihu

---

# DROPDOWN:
- type: dropdown
   id: download
   attributes:
      label: How did you download the software?
      options:
        - apt-get
        - Built from source
        - Homebrew
        - MacPorts
    validations:
      required: true
