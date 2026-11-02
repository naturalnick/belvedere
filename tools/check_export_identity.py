#!/usr/bin/env python3
"""Read-only scope gate: this project is authorized for Web export only."""
import configparser
from pathlib import Path

config = configparser.ConfigParser(interpolation=None)
config.read(Path(__file__).resolve().parents[1] / 'export_presets.cfg')
presets = [section for section in config.sections() if section.startswith('preset.') and not section.endswith('.options')]
assert presets, 'No export preset exists'
for section in presets:
    assert config[section].get('platform') == '"Web"', f'Unapproved native export preset: {section}'
for section in config.sections():
    for key in config[section]:
        assert not any(word in key.lower() for word in ('bundle_identifier', 'team_id', 'codesign', 'provisioning')), f'Unexpected Apple identity setting: {section}/{key}'
print('Export identity preflight: Web only; no Apple identity or signing settings')
