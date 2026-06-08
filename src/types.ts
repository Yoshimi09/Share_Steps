export type Profile = {
  id: string;
  username: string;
  target_steps: number;
  created_at: string;
  updated_at: string;
};

export type StepRecord = {
  id: string;
  user_id: string;
  date: string;
  steps: number;
  created_at: string;
  updated_at: string;
};

export type Group = {
  id: string;
  name: string;
  invite_code: string;
  created_by: string | null;
  created_at: string;
};

export type GroupMember = {
  id: string;
  group_id: string;
  user_id: string;
  joined_at: string;
  profile: Pick<Profile, 'id' | 'username' | 'target_steps'> | null;
};

export type RankingRow = {
  rank: number;
  userId: string;
  username: string;
  steps: number;
  targetSteps: number;
  achieved: boolean;
};
