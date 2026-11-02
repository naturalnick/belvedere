#!/usr/bin/env python3
"""Read-only export identity gate; never writes or refreshes its baseline."""
import configparser
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
config = configparser.ConfigParser(interpolation=None)
config.read(root / 'export_presets.cfg')
baseline = json.loads((root / 'apple-identity.json').read_text())
presets = [s for s in config.sections() if s.startswith('preset.') and not s.endswith('.options')]
assert presets, 'No export preset exists'
mac_count = 0
for section in presets:
    platform = config[section].get('platform', '').strip('"')
    assert platform in ('Web', 'macOS'), f'Unapproved native export platform: {section}/{platform}'
    options = config[section + '.options']
    if platform == 'macOS':
        mac_count += 1
        expected = {
            'application/bundle_identifier': json.dumps(baseline['bundle_identifier']),
            'codesign/codesign': str(baseline['codesign']),
            'notarization/notarization': str(baseline['notarization']),
        }
        assert config[section]['name'].strip('"') == baseline['preset'], f'Unexpected macOS preset: {section}'
        for key, approved in expected.items():
            actual = options.get(key)
            assert actual == approved, f'{section}/{key}: actual {actual!r}, baseline {approved!r}'
        assert baseline['codesign'] == 0 and baseline['notarization'] == 0, 'Only unsigned, unnotarized test export is authorized'
    for key, value in options.items():
        sensitive = any(word in key for word in ('team_id', 'identity', 'certificate', 'password', 'provisioning', 'apple_id', 'api_key'))
        assert not sensitive or value in ('', '""'), f'Unapproved signing/account field: {section}/{key}'
assert mac_count == 1, f'Expected one unsigned macOS test preset, found {mac_count}'
print('Export identity preflight: Web + local unsigned macOS test; com.puzzaholics.shiftingmanor; signing/notarization disabled')
