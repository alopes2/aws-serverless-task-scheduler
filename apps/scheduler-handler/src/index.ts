import type { ScheduledEvent } from 'aws-lambda';

type Event = {
  message: string;
};

export const handler = async (event: ScheduledEvent<Event>) => {
  console.log('Received scheduled event: ', event);

  const response = {
    statusCode: 200,
    body: JSON.stringify('Processed scheduled event'),
  };

  return response;
};
