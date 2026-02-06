from strictdoc.core.project_config import ProjectConfig


def create_config() -> ProjectConfig:
    global_exclude = [
        "/.venv",
        "/backend/.mvn",
        "/infra/node_modules"
    ]

    config = ProjectConfig(
        project_title="Health-E Pill Organizer",
        project_features=[
            "TABLE_SCREEN",
            "TRACEABILITY_SCREEN",
            "SEARCH",
            "TRACEABILITY_MATRIX_SCREEN",
            "REQUIREMENT_TO_SOURCE_TRACEABILITY",
            "SOURCE_FILE_LANGUAGE_PARSERS"
        ],
        include_doc_paths=[
            "/docs/**.sdoc",
        ],
        exclude_doc_paths=global_exclude,
        include_source_paths=[
            "/backend/**.java",
            "/backend/**.groovy",

            "/app/lib/**.dart",

            "/infra/**.ts",

            "/firmware/**.c",
            "/firmware/**.cpp",
            "/firmware/platformio.ini"
        ],
        exclude_source_paths=global_exclude
    )
    return config