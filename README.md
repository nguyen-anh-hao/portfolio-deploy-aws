# Portfolio Deploy — AWS Infrastructure

Infrastructure-as-Code cho ReactJS portfolio app, deploy lên AWS với chi phí tối thiểu.

---

## Kiến trúc tổng quan

```
Internet
   │
   ▼
[CloudFront CDN] ←── [WAF - Rate Limit + Managed Rules]
   │
   ├──► [S3 Bucket] (React static files)
   │
   └──► [Lambda Function URL] (API placeholder / future backend)
              │
              ▼
         [VPC - Private Subnets]
              │
              ▼
         (Future: RDS, ElastiCache, etc.)
```

### Tại sao không host React trực tiếp trên Lambda?

React là **static SPA** (HTML + JS + CSS sau khi `npm run build`). AWS best practice và cách rẻ nhất:
- **S3 + CloudFront** = serve static files (cực rẻ, cực nhanh)
- **Lambda** = dành cho backend/API động (đã chuẩn bị sẵn, để sau dùng)

Lambda để "host React" chỉ hợp lý với **SSR (Next.js, Remix)** — nếu sau này migrate sang SSR, có thể dùng [Lambda@Edge](https://aws.amazon.com/lambda/edge/).

---

## Chi phí ước tính

### Mặc định (minimal — chỉ host React Vite)

| Dịch vụ | Chi phí/tháng | Trạng thái |
|---------|--------------|------------|
| S3 | ~$0.01–0.50 | BẬT |
| CloudFront | ~$0.01–1.00 | BẬT |
| WAF | ~$7–10 | **TẮt** (`enable_waf = false`) |
| Lambda | FREE | **TẮt** (`enable_lambda = false`) |
| VPC | FREE | BẬT (sẵn sàng cho DB sau) |
| **Tổng** | **~$0–1/tháng** | ✔ Rẻ nhất |

### Khi mở rộng

| Dịch vụ | Bật khi | Chi phí thêm |
|---------|---------|-------------|
| WAF | Có traffic thực, cần chặn bot/spam | +~$7–10/tháng |
| Lambda | Cần backend API | FREE (1M req/month) |
| NAT Gateway | Lambda cần gọi external API | +~$32/tháng |

---

## Cấu trúc thư mục

```
Portfolio-Deploy/
├── terraform/                    # AWS Infrastructure (Terraform)
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── vpc/                  # VPC + subnets + IGW
│       ├── s3/                   # S3 bucket cho React build
│       ├── waf/                  # WAF Web ACL (us-east-1)
│       ├── cloudfront/           # CloudFront distribution
│       └── lambda/               # Lambda placeholder API
│
└── github-actions/               # Copy sang repo React của bạn
    └── workflows/
        ├── ci.yml                # Build + test khi tạo PR
        └── deploy.yml            # Deploy lên AWS khi merge vào main
```

---

## Hướng dẫn Deploy

### Prerequisites

- Terraform >= 1.5.0 ✅ (đã cài — `terraform --version`)
- AWS CLI v2 ✅ (đã cài — `aws --version`)
- AWS account (root hoặc Admin)

### Bước 0: Tạo IAM user riêng cho Terraform (không dùng root)

> ⚠️ **Không nên** chạy Terraform bằng root account. Script dưới đây tạo IAM user
> `terraform-deployer` với **quyền tối thiểu** chỉ đủ để deploy project này.

```powershell
# 1. Configure root/admin credentials tạm thời
aws configure
# AWS Access Key ID: <root access key>
# AWS Secret Access Key: <root secret key>
# Default region: ap-southeast-1
# Default output format: json

# 2. Chạy bootstrap script — tạo IAM user + policy + lưu credentials
powershell -ExecutionPolicy Bypass -File bootstrap\create-terraform-iam.ps1

# 3. Load credentials của terraform-deployer vào shell
. .\bootstrap\terraform.env.ps1

# 4. Kiểm tra (phải thấy terraform-deployer, KHÔNG phải root)
aws sts get-caller-identity
```

File `bootstrap\terraform.env.ps1` chứa Access Key của `terraform-deployer` — đã được thêm vào `.gitignore`, **không bao giờ commit file này**.

### Bước 1: Khởi tạo Terraform

```bash
cd terraform

# Copy và chỉnh sửa biến
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars nếu cần (mặc định đã rẻ nhất: WAF tắt, Lambda tắt)

terraform init
```

### Bước 2: Preview

```bash
terraform plan
```

### Bước 3: Deploy

```bash
terraform apply
```

Sau khi apply xong, Terraform sẽ in ra:
- `cloudfront_domain_name` — URL truy cập app
- `s3_bucket_name` — tên S3 bucket
- `cloudfront_distribution_id` — ID để dùng trong CI/CD
- `deploy_instructions` — hướng dẫn setup GitHub Secrets

### Bước 4: Lấy thông tin CI/CD credentials

```bash
# Lấy Access Key ID (public)
terraform output cicd_access_key_id

# Lấy Secret Access Key (sensitive)
terraform output -raw cicd_secret_access_key
```

---

## Cài đặt CI/CD cho React repo

### Bước 1: Copy GitHub Actions workflows

Copy toàn bộ thư mục `github-actions/workflows/` vào repo React của bạn:

```
your-react-repo/
└── .github/
    └── workflows/
        ├── ci.yml       ← copy từ github-actions/workflows/ci.yml
        └── deploy.yml   ← copy từ github-actions/workflows/deploy.yml
```

### Bước 2: Thêm GitHub Secrets

Vào **Settings → Secrets and variables → Actions** trong repo React, thêm:

| Secret Name | Giá trị |
|-------------|---------|
| `AWS_ACCESS_KEY_ID` | Output từ `terraform output cicd_access_key_id` |
| `AWS_SECRET_ACCESS_KEY` | Output từ `terraform output -raw cicd_secret_access_key` |
| `S3_BUCKET_NAME` | Output từ `terraform output s3_bucket_name` |
| `CLOUDFRONT_DISTRIBUTION_ID` | Output từ `terraform output cloudfront_distribution_id` |
| `AWS_REGION` | `ap-southeast-1` (hoặc region bạn chọn) |

### Bước 3: Thêm GitHub Variable (optional)

Vào **Settings → Secrets and variables → Variables** thêm:

| Variable Name | Giá trị |
|--------------|---------|
| `BUILD_DIR` | `dist` (Vite) hoặc `build` (Create React App) |

### Bước 4: Push code

```bash
git push origin main  # Trigger deploy tự động
```

---

## Mở rộng trong tương lai

### Thêm custom domain + HTTPS

1. Mua/chuyển domain về Route 53
2. Tạo ACM certificate ở **us-east-1** (bắt buộc cho CloudFront)
3. Uncomment phần `viewer_certificate` trong `modules/cloudfront/main.tf`
4. Thêm `domain_name` vào `terraform.tfvars`

### Thêm Backend API

Lambda đã được chuẩn bị sẵn. Để kết nối:
- **Lambda Function URL** (hiện có, free): truy cập qua URL từ `terraform output lambda_function_url`
- **API Gateway HTTP API** (~$1/M requests): thêm module `api_gateway` sau

### Thêm Database (RDS/Aurora)

VPC đã có private subnets sẵn sàng. Thêm:
```hcl
module "rds" {
  source             = "./modules/rds"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  ...
}
```

⚠️ **Lưu ý NAT Gateway**: Lambda trong private subnet **không có internet** (no NAT để tiết kiệm ~$32/tháng). Khi Lambda cần gọi external API, thêm NAT Gateway hoặc dùng [VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html) cho AWS services.

### Scale up CloudFront

Đổi `price_class` trong `modules/cloudfront/main.tf`:
- `PriceClass_100` — US + EU (rẻ nhất, hiện tại)
- `PriceClass_200` — + Asia Pacific
- `PriceClass_All` — Toàn cầu (đắt nhất nhưng nhanh nhất)

---

## Destroy (xóa tất cả resources)

```bash
cd terraform
terraform destroy
```

> ⚠️ Lệnh này sẽ **xóa vĩnh viễn** tất cả resources AWS. Chắc chắn trước khi chạy.
