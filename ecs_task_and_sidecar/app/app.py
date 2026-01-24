import time
import sys
from datetime import datetime

def main():
    print("Starting log generator...")
    while True:
        # 現在の日時を取得 (秒まで表示)
        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # 指定のフォーマットで標準出力へ出力
        print(f"Hello, World! {current_time}")
        
        # コンテナ環境ではバッファリングによりログが即時反映されないことがあるため、
        # 明示的にフラッシュする（DockerfileのENV設定でも対策しますが念のため）
        sys.stdout.flush()
        
        # 1秒待機
        time.sleep(1)

if __name__ == "__main__":
    main()
