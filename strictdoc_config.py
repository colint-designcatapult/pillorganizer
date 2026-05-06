from strictdoc.core.project_config import ProjectConfig


def create_config() -> ProjectConfig:
    global_exclude = [
        "/.venv",
        "/backend/.mvn",
        "/infra/node_modules",
        "/web",
        "/app",
        "/firmware"
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
            "/docs/requirements/0_stakeholder_and_risk/1_user_needs.sdoc",
            "/docs/requirements/0_stakeholder_and_risk/2_risk_analysis.sdoc",
            "/docs/requirements/1_system/system_reqs.sdoc",
            "/docs/requirements/2_vnv/*.sdoc",
            "/docs/requirements/2_software_reqs/control_plane.sdoc",
            "/docs/requirements/1_system/interface_control.sdoc",
        ],
        exclude_doc_paths=global_exclude,
        include_source_paths=[
            "/backend/**.java",
            "/backend/**.groovy"
        ],
        exclude_source_paths=global_exclude
    )
    return config