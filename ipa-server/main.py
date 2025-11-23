import os
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# CORS（必要なら調整）
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_ROOT = "uploads"
os.makedirs(UPLOAD_ROOT, exist_ok=True)


# ---------------------------
# 1. チャンクアップロード
# ---------------------------
@app.post("/upload-chunk")
async def upload_chunk(
    upload_id: str = Form(...),
    chunk_index: int = Form(...),
    file: UploadFile = File(...)
):
    # 保存ディレクトリ
    save_dir = os.path.join(UPLOAD_ROOT, upload_id)
    os.makedirs(save_dir, exist_ok=True)

    # チャンクファイルパス
    chunk_path = os.path.join(save_dir, f"{chunk_index}.part")

    # チャンク保存
    with open(chunk_path, "wb") as f:
        f.write(await file.read())

    return {"status": "ok", "chunk": chunk_index}


# ---------------------------
# 2. 結合エンドポイント
# ---------------------------
@app.post("/merge")
async def merge_files(upload_id: str = Form(...)):
    save_dir = os.path.join(UPLOAD_ROOT, upload_id)
    output_path = os.path.join(UPLOAD_ROOT, f"{upload_id}.ipa")

    if not os.path.exists(save_dir):
        return {"error": "upload_id not found"}

    # .part ファイル一覧を順番に並べる
    part_files = sorted(
        [f for f in os.listdir(save_dir) if f.endswith(".part")],
        key=lambda x: int(x.replace(".part", ""))
    )

    # 結合処理
    with open(output_path, "wb") as outfile:
        for part in part_files:
            with open(os.path.join(save_dir, part), "rb") as pf:
                outfile.write(pf.read())

    return {
        "status": "merged",
        "output": output_path,
        "parts": len(part_files)
    }


# ---------------------------
# 動作確認用
# ---------------------------
@app.get("/")
def home():
    return {"message": "IPA Upload Server Running!"}