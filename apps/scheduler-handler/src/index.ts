type ScheduledEvent = {
  message: string;
};

export const handler = async (event: ScheduledEvent) => {
  console.log('Received schedule event: ', event);

  const response = {
    statusCode: 200,
    body: JSON.stringify('Processed schedule event'),
  };

  return response;
};
