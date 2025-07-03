import { BadGatewayException, Injectable } from '@nestjs/common';
import { PostgresService } from '../shared/postgres.service';
import { LlmService } from '../shared/llm.service';

@Injectable()
export class ChatService {
  constructor(
    private readonly postgresService: PostgresService,
    private readonly llmService: LlmService,
  ) {}

  async createChatSession(userId: number) {
    const result = await this.postgresService.client.query<{
      id: number;
    }>('INSERT INTO chat_sessions (user_id) VALUES ($1) RETURNING id', [
      userId,
    ]);
    return result.rows[0];
  }

  async getChatSession(sessionId: number) {
    const result = await this.postgresService.client.query<{
      id: number;
      created_at: Date;
      user_id: number;
    }>(
      `
      SELECT chat_sessions.id, chat_sessions.created_at, chat_sessions.user_id, JSON_AGG(
        JSON_BUILD_OBJECT(
          'id', chat_messages.id,
          'content', chat_messages.content,
          'sender', chat_messages.sender,
          'openai_message_id', chat_messages.openai_message_id,
          'created_at', chat_messages.created_at,
          'message_type', chat_messages.message_type,
          'action', CASE
            WHEN chat_messages_actions.id IS NOT NULL THEN
              JSON_BUILD_OBJECT(
                'action_type', chat_messages_actions.action_type,
                'payload', chat_messages_actions.payload,
                'id', chat_messages_actions.id,
                'created_at', chat_messages_actions.created_at,
                'confirmed_at', chat_messages_actions.confirmed_at,
                'executed_at', chat_messages_actions.executed_at
              )
            ELSE NULL
          END
        )
      ) FILTER(WHERE chat_messages.id IS NOT NULL) AS messages
      FROM chat_sessions
      LEFT JOIN chat_messages ON chat_sessions.id = chat_messages.chat_session_id
      LEFT JOIN chat_messages_actions ON chat_messages.id = chat_messages_actions.chat_message_id
      WHERE chat_sessions.id = $1
      GROUP BY chat_sessions.id, chat_messages.chat_session_id
      `,
      [sessionId],
    );

    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0];
  }

  async addUserMessage(sessionId: number, content: string) {
    const chatMessages = await this.postgresService.client.query<{
      openai_message_id: string | null;
    }>(
      `SELECT openai_message_id FROM chat_messages WHERE chat_session_id = $1 AND sender = 'assistant' ORDER BY created_at DESC LIMIT 1`,
      [sessionId],
    );

    const userMessage = await this.addMessageToSession(
      sessionId,
      content,
      'user',
    );

    const llmResponse = await this.llmService.answerMessage(
      content,
      chatMessages.rows[0]?.openai_message_id || null,
    );

    if (!llmResponse) {
      throw new BadGatewayException('Failed to get a response from LLM');
    }

    const llmMessage = await this.addMessageToSession(
      sessionId,
      llmResponse.message,
      'assistant',
      llmResponse.responseId,
      'text',
    );

    if (llmResponse.action.type === 'suggest_carts') {
      await this.postgresService.client.query(
        `
        INSERT INTO chat_messages_actions (chat_message_id, action_type, payload)
        VALUES ($1, $2, $3)
        ON CONFLICT (chat_message_id, action_type) DO NOTHING
      `,
        [
          llmMessage.id,
          llmResponse.action.type,
          JSON.stringify(llmResponse.action.payload),
        ],
      );
    }

    return userMessage;
  }

  private async addMessageToSession(
    sessionId: number,
    content: string,
    sender: 'user' | 'assistant',
    openaiMessageId?: string,
    messageType: 'text' | 'suggest_carts_result' = 'text',
  ) {
    const result = await this.postgresService.client.query<{
      id: number;
      content: string;
      sender: string;
      openai_message_id: string | null;
      created_at: Date;
      message_type: string;
    }>(
      `INSERT INTO chat_messages (chat_session_id, content, sender, openai_message_id, message_type)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [sessionId, content, sender, openaiMessageId || null, messageType],
    );
    return result.rows[0];
  }
}
