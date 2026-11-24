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


def test_large_image_is_resized():
    result, _ = process_image(sample_image(size=(2400, 1200)))
    with Image.open(BytesIO(result)) as image:
        assert image.size == (1600, 800)


def test_watermark_option_returns_valid_jpeg():
    result, _ = process_image(sample_image(), watermark_text="PILOT")
    with Image.open(BytesIO(result)) as image:
        assert image.format == "JPEG"


def test_empty_payload_rejected():
    with pytest.raises(ValueError, match="Empty"):
        process_image(b"")


def test_invalid_payload_rejected():
    with pytest.raises(ValueError):
        process_image(b"not-an-image")


def test_unsupported_format_rejected():
    with pytest.raises(ValueError, match="Unsupported"):
        process_image(sample_image("GIF"))
