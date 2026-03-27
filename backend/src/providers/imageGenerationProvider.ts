export interface GenerationInput {
  baseImageURL: string;
  prompt: string;
  negativePrompt: string;
}

export interface ImageGenerationProvider {
  generate(input: GenerationInput): Promise<ArrayBuffer>;
}

class ReplicateProvider implements ImageGenerationProvider {
  private readonly apiKey: string;
  private readonly modelId: string;

  constructor() {
    this.apiKey = process.env.REPLICATE_API_KEY!;
    this.modelId = process.env.REPLICATE_MODEL_ID!;
  }

  async generate(input: GenerationInput): Promise<ArrayBuffer> {
    // Create prediction
    const createRes = await fetch('https://api.replicate.com/v1/predictions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        version: this.modelId,
        input: {
          image: input.baseImageURL,
          prompt: input.prompt,
          negative_prompt: input.negativePrompt,
          num_inference_steps: 30,
          guidance_scale: 7.5,
          ip_adapter_scale: 0.8,
        },
      }),
    });

    if (!createRes.ok) {
      const err = await createRes.text();
      throw new Error(`Replicate create prediction failed: ${err}`);
    }

    const prediction = (await createRes.json()) as { id: string };
    const predictionId: string = prediction.id;

    // Poll until complete
    const maxAttempts = 60;
    for (let i = 0; i < maxAttempts; i++) {
      await sleep(2000);

      const pollRes = await fetch(`https://api.replicate.com/v1/predictions/${predictionId}`, {
        headers: { Authorization: `Bearer ${this.apiKey}` },
      });
      const status = (await pollRes.json()) as {
        status: string;
        output?: string | string[];
        error?: string;
      };

      if (status.status === 'succeeded') {
        const outputURL: string = Array.isArray(status.output) ? status.output[0] : (status.output as string);
        const imgRes = await fetch(outputURL);
        if (!imgRes.ok) throw new Error('Failed to download generated image');
        return imgRes.arrayBuffer();
      }

      if (status.status === 'failed' || status.status === 'canceled') {
        throw new Error(`Replicate prediction ${status.status}: ${status.error ?? 'unknown'}`);
      }
    }

    throw new Error('Replicate prediction timed out after 2 minutes');
  }
}

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Factory — swap provider by changing AI_PROVIDER env var
export function getImageGenerationProvider(): ImageGenerationProvider {
  const provider = process.env.AI_PROVIDER ?? 'replicate';
  switch (provider) {
    case 'replicate':
      return new ReplicateProvider();
    default:
      throw new Error(`Unknown AI provider: ${provider}`);
  }
}
