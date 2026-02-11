# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'Health-E Pill Organizer'
copyright = '2026, Design Catapult, Inc'
author = 'Design Catapult, Inc'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = ['rst2pdf.pdfbuilder', 'docxbuilder']

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']



# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'alabaster'
html_static_path = ['_static']

# PDF/docx export
pdf_documents = [('index', u'requirements', u'Health-E Pill Organizer Requirements', u'Design Catapult, Inc'),]

docx_documents = [('index', 'requirements.docx', {
    'title': 'Health-E Pill Organizer Requirements',
    'author': 'Design Catapult, Inc',
    'subject': 'Requirements',
    'keywords': ['sphinx']
}, True)]
docx_pagebreak_before_section = 2
docx_pagebreak_after_table_of_contents = 1