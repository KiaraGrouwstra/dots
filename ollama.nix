{
  services.ollama = {
    enable = true;
    host = "127.0.0.1";
    port = 11434;
    acceleration = "rocm";
    rocmOverrideGfx = "9.0.0";
    # https://ollama.com/library
    #     loadModels = [
    #       "deepscaler" # 1.5b: A fine-tuned version of Deepseek-R1-Distilled-Qwen-1.5B that surpasses the performance of OpenAI’s o1-preview with just 1.5B parameters on popular math evaluations.
    #       "openthinker" # 7b / 32b: A fully open-source family of reasoning models built using a dataset derived by distilling DeepSeek-R1.
    #       # "r1-1776" # 70b / 671b: A version of the DeepSeek-R1 model that has been post trained to provide unbiased, accurate, and factual information by Perplexity.
    #       # "deepseek-v3" # 671b: A strong Mixture-of-Experts (MoE) language model with 671B total parameters with 37B activated for each token.
    #     ];
    #   };
    #   # nginx by default runs with ProtectHome = true
    # }
  };
}
