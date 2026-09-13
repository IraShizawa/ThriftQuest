const MAX_IMAGE_BYTES = 4 * 1024 * 1024;

export default async function handler(request, response) {
  if (request.method !== "POST") {
    response.setHeader("Allow", "POST");
    return response.status(405).json({ error: "Method not allowed" });
  }

  if (!process.env.OPENAI_API_KEY) {
    return response.status(500).json({ error: "OpenAI API key is not configured on the server." });
  }

  try {
    const { bossName = "", imageBase64 } = request.body ?? {};
    if (!imageBase64 || typeof imageBase64 !== "string") {
      return response.status(400).json({ error: "imageBase64 is required." });
    }

    const imageBuffer = Buffer.from(imageBase64, "base64");
    if (!imageBuffer.length || imageBuffer.length > MAX_IMAGE_BYTES) {
      return response.status(400).json({ error: "Image is empty or too large." });
    }

    const formData = new FormData();
    formData.append("model", "gpt-image-1");
    formData.append("prompt", promptFor(bossName));
    formData.append("size", "1024x1024");
    formData.append("quality", "low");
    formData.append("output_format", "png");
    formData.append("input_fidelity", "high");
    formData.append("image[]", new Blob([imageBuffer], { type: "image/jpeg" }), "product.jpg");

    const openAIResponse = await fetch("https://api.openai.com/v1/images/edits", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${process.env.OPENAI_API_KEY}`
      },
      body: formData
    });

    const payload = await openAIResponse.json().catch(() => null);
    if (!openAIResponse.ok) {
      return response.status(openAIResponse.status).json({
        error: payload?.error?.message ?? "OpenAI image generation failed."
      });
    }

    const imageBase64Output = payload?.data?.[0]?.b64_json;
    if (!imageBase64Output) {
      return response.status(502).json({ error: "OpenAI response did not include an image." });
    }

    return response.status(200).json({ imageBase64: imageBase64Output });
  } catch (error) {
    return response.status(500).json({ error: error?.message ?? "Unexpected server error." });
  }
}

function promptFor(bossName) {
  const displayName = String(bossName || "欲しいもの").trim() || "欲しいもの";
  return `
Turn the referenced product image into an original RPG boss character for a Japanese savings RPG app.
Preserve the product's key silhouette, color palette, and recognizable details, but transform it into a fantasy boss monster.
Make it dramatic, collectible, playful, and suitable for a dark mobile game UI.
Do not include text, logos, prices, UI, watermark, or realistic shopping-page background.
Center the character, full body, clean readable silhouette, high contrast, game illustration style.
Boss theme: ${displayName}
`.trim();
}
