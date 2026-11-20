"""Write public Flutter URL defines as JSON, never interpolated shell commands."""
import argparse
import html
import json
import os
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit


def base_url(name, raw):
    value = raw.strip()
    if not value:
        if name == 'API_BASE_URL':
            raise ValueError('API_BASE_URL is required.')
        return None
    if any(character.isspace() or ord(character) < 32 for character in value):
        raise ValueError(f'{name} must not contain whitespace/control characters.')
    parsed = urlsplit(value)
    if parsed.scheme not in ('http', 'https') or not parsed.hostname or parsed.username is not None or parsed.password is not None or parsed.query or parsed.fragment:
        raise ValueError(f'{name} must be an absolute HTTP(S) URL without credentials, query or fragment.')
    _ = parsed.port  # Reject malformed ports too.
    path = parsed.path.rstrip('/')
    if name == 'API_BASE_URL' and path.lower().endswith('/api'):
        path = path[:-4]  # ApiConfig appends /api itself.
    if name != 'API_BASE_URL' and path.endswith(('/health', '/api/v1/speech', '/api/v1/recognitions')):
        raise ValueError(f'{name} must be a service base URL, not an individual endpoint.')
    return urlunsplit((parsed.scheme, parsed.netloc, path, '', ''))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    output = parser.parse_args().output
    values = {name: base_url(name, os.environ.get(name, '')) for name in ('API_BASE_URL', 'TTS_BASE_URL', 'VISION_BASE_URL')}
    values = {name: value for name, value in values.items() if value is not None}
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(values, indent=2) + '\n', encoding='utf-8')
    print('Prepared APK URL configuration; no credentials are embedded by this script.')
    summary = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary:
        with open(summary, 'a', encoding='utf-8') as report:
            report.write('## APK service configuration\n')
            for name, value in values.items():
                report.write(f'- {name}: <code>{html.escape(value)}</code>\n')
            if len(values) < 3:
                report.write('\nTTS/Vision URLs are optional. Unconfigured services retain the app defaults; this workflow does not deploy AI services.\n')
    return values


if __name__ == '__main__':
    main()
