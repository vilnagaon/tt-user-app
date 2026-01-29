
import { GoogleGenAI } from "@google/genai";
import { SyncLog } from "../types";

const ai = new GoogleGenAI({ apiKey: process.env.API_KEY || "" });

export const analyzeLogs = async (logs: SyncLog[]) => {
  const prompt = `Analyze the following synchronization logs for a CRM system (Teatower) and provide a brief professional summary (in French) of current issues and suggested fixes:
  ${JSON.stringify(logs.map(l => ({ source: l.source, status: l.status, details: l.details })))}
  
  Focus on identifying patterns and technical resolutions. Keep it under 150 words.`;

  try {
    const response = await ai.models.generateContent({
      model: "gemini-3-flash-preview",
      contents: prompt,
      config: {
        systemInstruction: "Tu es un expert en intégration de systèmes (Odoo, Shopify, Mailchimp) pour Teatower. Analyse les logs et propose des solutions concrètes.",
        temperature: 0.7,
      }
    });
    return response.text;
  } catch (error) {
    console.error("Gemini Error:", error);
    return "Impossible d'analyser les logs pour le moment.";
  }
};

export const suggestTeaRecommendation = async (preferences: string[]) => {
  const prompt = `Based on these tea preferences: ${preferences.join(", ")}, suggest 3 specific Teatower product categories or blends that might interest the user. Answer in French, friendly tone.`;

  try {
    const response = await ai.models.generateContent({
      model: "gemini-3-flash-preview",
      contents: prompt,
      config: {
        systemInstruction: "Tu es un sommelier du thé chez Teatower.",
        temperature: 0.8,
      }
    });
    return response.text;
  } catch (error) {
    return "Découvrez nos dernières nouveautés en boutique !";
  }
};
