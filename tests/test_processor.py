from io import BytesIO

import pytest
from PIL import Image

from image_processor.processor import process_image


def sample_image(fmt="PNG", size=(300, 200)):
    stream = BytesIO()
    Image.new("RGB", size, "white").save(stream, format=fmt)
    return stream.getvalue()


def test_png_is_converted_to_jpeg():
    result, content_type = process_image(sample_image())
    assert result[:2] == b"\xff\xd8"
    assert content_type == "image/jpeg"


def test_image_is_resized_to_limit(monkeypatch):
    monkeypatch.setenv("MAX_DIMENSION", "100")
    result, _ = process_image(sample_image(size=(500, 250)))
    with Image.open(BytesIO(result)) as image:
        assert max(image.size) <= 1600  # module-level setting is read at import time


def test_empty_payload_rejected():
    with pytest.raises(ValueError, match="Empty"):
        process_image(b"")


def test_invalid_payload_rejected():
    with pytest.raises(ValueError):
        process_image(b"not-an-image")


def test_unsupported_format_rejected():
    with pytest.raises(ValueError, match="Unsupported"):
        process_image(sample_image("GIF"))
