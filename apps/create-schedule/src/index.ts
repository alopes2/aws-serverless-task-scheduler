import {
  SchedulerClient,
  CreateScheduleCommand,
  CreateScheduleInput,
} from '@aws-sdk/client-scheduler';
import { randomUUID } from 'crypto';

const schedulerClient = new SchedulerClient();
const delay = 1000 * 60 * 1;

export const handler = async () => {
  const id = randomUUID();
  const name = `one-time-schedule-${id}`;
  const scheduledDate = new Date(Date.now() + delay);
  const formattedDate = getFormattedDate(scheduledDate);

  const input: CreateScheduleInput = {
    Name: name,
    ScheduleExpression: `at(${formattedDate})`,
    ScheduleExpressionTimezone: 'UTC',
    ActionAfterCompletion: 'DELETE',
    Target: {
      Arn: process.env.TARGET_ARN,
      RoleArn: process.env.ROLE_ARN,
      DeadLetterConfig: {
        Arn: process.env.DEAD_LETTER_ARN,
      },
    },
    FlexibleTimeWindow: {
      Mode: 'OFF',
    },
  };

  try {
    console.log(
      'Creating schedule %s to be process at %s',
      name,
      formattedDate
    );

    await schedulerClient.send(new CreateScheduleCommand(input));

    console.log('Successfully created schedule');

    const response = {
      statusCode: 200,
      body: JSON.stringify('Processed schedule event'),
    };

    return response;
  } catch (error: any) {
    console.error('Error creating schedule: %s', error.message);

    throw error;
  }
};

function getFormattedDate(date: Date): string {
  const formattedDate = `${
    date.getUTCFullYear
  }-${date.getUTCMonth()}-${date.getUTCDate()}T${date.getUTCHours()}:${date.getUTCMinutes()}:${date.getUTCSeconds()}`;

  return formattedDate;
}
