# Health Backend (Node.js + MongoDB)

## Setup

1. Copy `.env.example` to `.env` and set `MONGODB_URI`.
2. Install dependencies:

```bash
npm install
```

3. Start MongoDB locally or via Docker:

```bash
docker run -d --name mongo -p 27017:27017 mongo:6
```

4. Run server:

```bash
npm run dev
```

## API

- POST `/api/steps` — Save daily step summary
- POST `/api/workouts` — Save workout sessions (array)
- GET `/api/steps?userId={id}&start={iso}&end={iso}` — Query steps
- GET `/api/workouts?userId={id}&start={iso}&end={iso}` — Query workouts

Returns `{ ok: boolean, data?: any, error?: string }`.
