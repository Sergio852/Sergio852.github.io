import { defineCollection, z } from "astro:content";
import { glob } from "astro/loaders";

const practicas = defineCollection({
  loader: glob({
    pattern: "**/*.md",
    base: "./src/content/practicas"
  }),
  schema: z.object({
    title: z.string(),
    subject: z.string(),
    description: z.string(),
    date: z.coerce.date(),
    tags: z.array(z.string()).default([]),
    pdf: z.string().optional()
  })
});

export const collections = {
  practicas
};
