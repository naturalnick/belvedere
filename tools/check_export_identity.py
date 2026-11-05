#!/usr/bin/env python3
"""Read-only export identity gate; never writes or refreshes its baseline."""
import configparser
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
config = configparser.ConfigParser(interpolation=None)
config.read(root / 'export_presets.cfg')
baseline = json.loads((root / 'apple-identity.json').read_text())
team = baseline['team_id']
test = baseline['test_preset']
release = baseline['release_preset']
assert team in release['identity'], 'Release identity does not name the approved team'
assert test['codesign'] == 0 and test['notarization'] == 0, 'The test preset must stay unsigned and unnotarized'
presets = [s for s in config.sections() if s.startswith('preset.') and not s.endswith('.options')]
assert presets, 'No export preset exists'
mac_names = []
for section in presets:
    platform = config[section].get('platform', '').strip('"')
    name = config[section].get('name', '').strip('"')
    assert platform in ('Web', 'macOS', 'Windows Desktop'), f'Unapproved native export platform: {section}/{platform}'
    options = config[section + '.options']
    allowed = {}
    if platform == 'Windows Desktop':
        assert options.get('codesign/enable') == 'false', f'{section}: only an unsigned Windows test export is authorized'
    if platform == 'macOS':
        mac_names.append(name)
        assert name in (test['name'], release['name']), f'Unexpected macOS preset: {section}/{name}'
        approved = test if name == test['name'] else release
        expected = {
            'application/bundle_identifier': json.dumps(baseline['bundle_identifier']),
            'codesign/codesign': str(approved['codesign']),
            'notarization/notarization': str(approved['notarization']),
        }
        if name == release['name']:
            allowed = {
                'codesign/apple_team_id': json.dumps(team),
                'codesign/identity': json.dumps(release['identity']),
            }
            expected.update(allowed)
        for key, value in expected.items():
            actual = options.get(key)
            assert actual == value, f'{section}/{key}: actual {actual!r}, baseline {value!r}'
    for key, value in options.items():
        sensitive = any(word in key for word in ('team_id', 'identity', 'certificate', 'password', 'provisioning', 'apple_id', 'api_key'))
        assert not sensitive or key in allowed or value in ('', '""'), f'Unapproved signing/account field: {section}/{key}'
assert sorted(mac_names) == sorted([test['name'], release['name']]), f'Expected the test and release macOS presets, found {mac_names}'
print(f"Export identity preflight: Web, unsigned Windows and macOS tests, signed macOS release; {baseline['bundle_identifier']}; team {team}")
