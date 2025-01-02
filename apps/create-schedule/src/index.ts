import {
  SchedulerClient,
  CreateScheduleCommand,
  CreateScheduleInput,
} from '@aws-sdk/client-scheduler';
import { randomUUID } from 'crypto';

const schedulerClient = new SchedulerClient();
const delay = 1000 * 60 * 1;

type Event = {
  message: string;
};

export const handler = async () => {
  const id = randomUUID();
  const name = `one-time-schedule-${id}`;
  const scheduledDate = new Date(Date.now() + delay);
  const formattedDate = getFormattedDate(scheduledDate);

  const eventBody: Event = {
    message: `Event trigger for ID ${id}`,
  };

  const input: CreateScheduleInput = {
    Name: name,
    ScheduleExpression: `at(${formattedDate})`, //format yyyy-MM-ddTHH:mm:ss
    ScheduleExpressionTimezone: 'UTC',
    ActionAfterCompletion: 'DELETE',
    Target: {
      Arn: process.env.TARGET_ARN,
      RoleArn: process.env.ROLE_ARN,
      Input: JSON.stringify(eventBody),
      // DeadLetterConfig: {
      //   Arn: process.env.DEAD_LETTER_ARN,
      // },
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
    console.error('Error creating schedule: %s', error);

    throw error;
  }
};

// Converts date to format yyyy-MM-ddTHH:mm:ss
function getFormattedDate(date: Date): string {
  const year = date.getUTCFullYear();
  const month = getValueWithPrefix(date.getUTCMonth() + 1);
  const day = getValueWithPrefix(date.getUTCDate());
  const hours = getValueWithPrefix(date.getUTCHours());
  const minutes = getValueWithPrefix(date.getUTCMinutes());
  const seconds = getValueWithPrefix(date.getUTCSeconds());

  const formattedDate = `${year}-${month}-${day}T${hours}:${minutes}:${seconds}`;

  return formattedDate;
}

function getValueWithPrefix(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}
