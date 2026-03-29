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
  private readonly modelId: string; // format: "owner/model-name"

  constructor() {
    this.apiKey = process.env.REPLICATE_API_KEY!;
    this.modelId = process.env.REPLICATE_MODEL_ID!;
  }

  async generate(input: GenerationInput): Promise<ArrayBuffer> {
    // Use the model-based predictions endpoint (no version hash needed)
    const createRes = await fetch(`https://api.replicate.com/v1/models/${this.modelId}/predictions`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
        Prefer: 'wait=60', // wait up to 60s for result inline
      },
      body: JSON.stringify({
        input: {
          image: input.baseImageURL,
          prompt: input.prompt,
          strength: 0.75,
          num_inference_steps: 28,
          guidance: 3.5,
        },
      }),
    });

    if (!createRes.ok) {
      const err = await createRes.text();
      throw new Error(`Replicate create prediction failed: ${err}`);
    }

    const prediction = (await createRes.json()) as {
      id: string;
      status: string;
      output?: string | string[];
      error?: string;
    };

    // If the Prefer: wait header returned a completed result, use it directly
    if (prediction.status === 'succeeded') {
      return this.downloadOutput(prediction.output);
    }

    if (prediction.status === 'failed' || prediction.status === 'canceled') {
      throw new Error(`Replicate prediction ${prediction.status}: ${prediction.error ?? 'unknown'}`);
    }

    // Otherwise poll until complete
    const predictionId: string = prediction.id;
    const maxAttempts = 60;
    for (let i = 0; i < maxAttempts; i++) {
      await sleep(3000);

      const pollRes = await fetch(`https://api.replicate.com/v1/predictions/${predictionId}`, {
        headers: { Authorization: `Bearer ${this.apiKey}` },
      });
      const status = (await pollRes.json()) as {
        status: string;
        output?: string | string[];
        error?: string;
      };

      if (status.status === 'succeeded') {
        return this.downloadOutput(status.output);
      }

      if (status.status === 'failed' || status.status === 'canceled') {
        throw new Error(`Replicate prediction ${status.status}: ${status.error ?? 'unknown'}`);
      }
    }

    throw new Error('Replicate prediction timed out after 3 minutes');
  }

  private async downloadOutput(output: string | string[] | undefined): Promise<ArrayBuffer> {
    const outputURL: string = Array.isArray(output) ? output[0] : (output as string);
    if (!outputURL) throw new Error('Replicate returned no output URL');
    const imgRes = await fetch(outputURL);
    if (!imgRes.ok) throw new Error('Failed to download generated image from Replicate');
    return imgRes.arrayBuffer();
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
