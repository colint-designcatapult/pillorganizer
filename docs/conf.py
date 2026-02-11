# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

# This function runs after -D overrides are applied so we can inject version into the
# docx config.
def setup(app):
    def update_docx_subject(app, config):
        
        if config.docx_documents:
            for doc in config.docx_documents:
                metadata = doc[2]
                
                # Append the version from the command line (-D version=...)
                # config.version will now hold the correct GIT_SHA
                metadata['subject'] = f"Version {config.version}"

    # Connect this function to the 'config-inited' event
    app.connect('config-inited', update_docx_subject)

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
    'creator': 'Design Catapult, Inc',
    'subject': 'Unversioned'
}, True)]
docx_pagebreak_before_section = 2
docx_pagebreak_after_table_of_contents = 1