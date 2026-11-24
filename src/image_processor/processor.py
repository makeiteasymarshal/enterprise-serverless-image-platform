from __future__ import annotations

import io
import logging
import os
import warnings
from PIL import Image, ImageDraw, ImageFont, ImageOps, UnidentifiedImageError

logger = logging.getLogger(__name__)
MAX_INPUT_BYTES = int(os.getenv("MAX_INPUT_BYTES", "10485760"))
MAX_IMAGE_PIXELS = int(os.getenv("MAX_IMAGE_PIXELS", "40000000"))
MAX_DIMENSION = int(os.getenv("MAX_DIMENSION", "1600"))
JPEG_QUALITY = int(os.getenv("JPEG_QUALITY", "85"))


def process_image(data: bytes, watermark_text: str | None = None) -> tuple[bytes, str]:
    """Validate, normalize, resize and optionally watermark an image."""
    if not data:
        raise ValueError("Empty image payload")
    if len(data) > MAX_INPUT_BYTES:
        raise ValueError("Image exceeds configured input size limit")

    Image.MAX_IMAGE_PIXELS = MAX_IMAGE_PIXELS
    warnings.simplefilter("error", Image.DecompressionBombWarning)
    try:
        with Image.open(io.BytesIO(data)) as source:
            if source.format not in {"JPEG", "PNG", "WEBP"}:
                raise ValueError(f"Unsupported image format: {source.format}")
            image = ImageOps.exif_transpose(source).convert("RGB")
            image.thumbnail((MAX_DIMENSION, MAX_DIMENSION), Image.Resampling.LANCZOS)
            if watermark_text:
                draw = ImageDraw.Draw(image)
                margin = max(8, image.width // 50)
                draw.text(
                    (image.width - margin, image.height - margin),
                    watermark_text[:80],
                    fill=(255, 255, 255),
                    anchor="rb",
                    stroke_width=1,
                    stroke_fill=(0, 0, 0),
                )
            output = io.BytesIO()
            image.save(output, format="JPEG", quality=JPEG_QUALITY, optimize=True)
            return output.getvalue(), "image/jpeg"
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError,
            Image.DecompressionBombWarning) as exc:
        raise ValueError("Invalid or unsafe image") from exc
