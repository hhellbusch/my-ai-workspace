#!/bin/bash
# find-cluster-aws.sh - Find OpenShift cluster resources in AWS

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SEARCH_TERM="${1:-}"
REGION="${2:-us-east-1}"

usage() {
    cat <<EOF
Usage: $0 <search-term> [region]

Find OpenShift cluster resources in AWS by cluster name or keyword.

Arguments:
    search-term    Cluster name or keyword to search for (required)
    region         AWS region (default: us-east-1)

Examples:
    $0 my-ocp-cluster us-east-1
    $0 production
    $0 cluster-abc123

Environment Variables:
    AWS_PROFILE    AWS profile to use (optional)
    AWS_REGION     AWS region (overridden by positional arg)

Output:
    - Lists all resources matching the search term
    - Estimates monthly costs
    - Provides resource counts
    - Generates cleanup commands
EOF
}

if [ -z "$SEARCH_TERM" ]; then
    usage
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}AWS OpenShift Cluster Resource Finder${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Search Term: ${YELLOW}$SEARCH_TERM${NC}"
echo -e "Region:      ${YELLOW}$REGION${NC}"
echo -e "AWS Account: ${YELLOW}$(aws sts get-caller-identity --query Account --output text)${NC}"
echo ""

# Check AWS CLI availability
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Please install it first.${NC}"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &>/dev/null; then
    echo -e "${RED}❌ AWS credentials not configured or invalid${NC}"
    exit 1
fi

echo -e "${GREEN}✓ AWS credentials valid${NC}"
echo ""

# Initialize counters
INSTANCE_COUNT=0
VOLUME_COUNT=0
LB_COUNT=0
SG_COUNT=0
VPC_COUNT=0
S3_COUNT=0

echo -e "${BLUE}🔍 Searching for resources...${NC}"
echo ""

# ============================================================================
# EC2 INSTANCES
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}EC2 Instances${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

INSTANCES=$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters "Name=tag:kubernetes.io/cluster/${SEARCH_TERM},Values=owned" \
    --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0],PrivateIpAddress,LaunchTime]' \
    --output text 2>/dev/null || echo "")

if [ -n "$INSTANCES" ]; then
    echo "$INSTANCES" | while read instance; do
        INSTANCE_COUNT=$((INSTANCE_COUNT + 1))
        echo "  $instance"
    done | column -t
    INSTANCE_COUNT=$(echo "$INSTANCES" | wc -l)
    echo -e "${GREEN}Found: $INSTANCE_COUNT instances${NC}"
else
    # Try alternative search by name pattern
    INSTANCES_ALT=$(aws ec2 describe-instances \
        --region "$REGION" \
        --filters "Name=tag:Name,Values=*${SEARCH_TERM}*" \
        --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0],PrivateIpAddress]' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$INSTANCES_ALT" ]; then
        echo "$INSTANCES_ALT" | column -t
        INSTANCE_COUNT=$(echo "$INSTANCES_ALT" | wc -l)
        echo -e "${GREEN}Found: $INSTANCE_COUNT instances (by name pattern)${NC}"
    else
        echo -e "${YELLOW}No instances found${NC}"
    fi
fi
echo ""

# ============================================================================
# LOAD BALANCERS
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Load Balancers (ALB/NLB)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

LBS=$(aws elbv2 describe-load-balancers \
    --region "$REGION" \
    --query "LoadBalancers[?contains(LoadBalancerName, '${SEARCH_TERM}')].[LoadBalancerName,Type,DNSName,State.Code]" \
    --output text 2>/dev/null || echo "")

if [ -n "$LBS" ]; then
    echo "$LBS" | column -t
    LB_COUNT=$(echo "$LBS" | wc -l)
    echo -e "${GREEN}Found: $LB_COUNT load balancers${NC}"
else
    echo -e "${YELLOW}No load balancers found${NC}"
fi
echo ""

# ============================================================================
# CLASSIC LOAD BALANCERS
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Classic Load Balancers${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

CLASSIC_LBS=$(aws elb describe-load-balancers \
    --region "$REGION" \
    --query "LoadBalancerDescriptions[?contains(LoadBalancerName, '${SEARCH_TERM}')].[LoadBalancerName,DNSName]" \
    --output text 2>/dev/null || echo "")

if [ -n "$CLASSIC_LBS" ]; then
    echo "$CLASSIC_LBS" | column -t
    CLASSIC_LB_COUNT=$(echo "$CLASSIC_LBS" | wc -l)
    LB_COUNT=$((LB_COUNT + CLASSIC_LB_COUNT))
    echo -e "${GREEN}Found: $CLASSIC_LB_COUNT classic load balancers${NC}"
else
    echo -e "${YELLOW}No classic load balancers found${NC}"
fi
echo ""

# ============================================================================
# VOLUMES
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}EBS Volumes${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

VOLUMES=$(aws ec2 describe-volumes \
    --region "$REGION" \
    --filters "Name=tag:kubernetes.io/cluster/${SEARCH_TERM},Values=owned" \
    --query 'Volumes[*].[VolumeId,Size,State,VolumeType]' \
    --output text 2>/dev/null || echo "")

if [ -n "$VOLUMES" ]; then
    echo "$VOLUMES" | column -t
    VOLUME_COUNT=$(echo "$VOLUMES" | wc -l)
    TOTAL_SIZE=$(echo "$VOLUMES" | awk '{sum+=$2} END {print sum}')
    echo -e "${GREEN}Found: $VOLUME_COUNT volumes (Total: ${TOTAL_SIZE}GB)${NC}"
else
    echo -e "${YELLOW}No volumes found${NC}"
fi
echo ""

# ============================================================================
# SECURITY GROUPS
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Security Groups${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

SGS=$(aws ec2 describe-security-groups \
    --region "$REGION" \
    --filters "Name=tag:kubernetes.io/cluster/${SEARCH_TERM},Values=owned" \
    --query 'SecurityGroups[*].[GroupId,GroupName,VpcId]' \
    --output text 2>/dev/null || echo "")

if [ -n "$SGS" ]; then
    echo "$SGS" | column -t
    SG_COUNT=$(echo "$SGS" | wc -l)
    echo -e "${GREEN}Found: $SG_COUNT security groups${NC}"
else
    echo -e "${YELLOW}No security groups found${NC}"
fi
echo ""

# ============================================================================
# VPC
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}VPCs${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

VPCS=$(aws ec2 describe-vpcs \
    --region "$REGION" \
    --filters "Name=tag:kubernetes.io/cluster/${SEARCH_TERM},Values=owned" \
    --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0],State]' \
    --output text 2>/dev/null || echo "")

if [ -n "$VPCS" ]; then
    echo "$VPCS" | column -t
    VPC_COUNT=$(echo "$VPCS" | wc -l)
    echo -e "${GREEN}Found: $VPC_COUNT VPCs${NC}"
else
    echo -e "${YELLOW}No VPCs found${NC}"
fi
echo ""

# ============================================================================
# S3 BUCKETS
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}S3 Buckets${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

S3_BUCKETS=$(aws s3api list-buckets \
    --query "Buckets[?contains(Name, '${SEARCH_TERM}')].Name" \
    --output text 2>/dev/null || echo "")

if [ -n "$S3_BUCKETS" ]; then
    for bucket in $S3_BUCKETS; do
        SIZE=$(aws s3 ls s3://$bucket --recursive --summarize 2>/dev/null | grep "Total Size" | awk '{print $3}' || echo "0")
        SIZE_MB=$((SIZE / 1024 / 1024))
        echo "  $bucket (${SIZE_MB}MB)"
        S3_COUNT=$((S3_COUNT + 1))
    done
    echo -e "${GREEN}Found: $S3_COUNT buckets${NC}"
else
    echo -e "${YELLOW}No S3 buckets found${NC}"
fi
echo ""

# ============================================================================
# ROUTE53
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Route53 Hosted Zones${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

R53_ZONES=$(aws route53 list-hosted-zones \
    --query "HostedZones[?contains(Name, '${SEARCH_TERM}')].[Id,Name,ResourceRecordSetCount]" \
    --output text 2>/dev/null || echo "")

if [ -n "$R53_ZONES" ]; then
    echo "$R53_ZONES" | column -t
    R53_COUNT=$(echo "$R53_ZONES" | wc -l)
    echo -e "${GREEN}Found: $R53_COUNT hosted zones${NC}"
else
    echo -e "${YELLOW}No Route53 zones found${NC}"
fi
echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SUMMARY${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Search Term:       ${YELLOW}$SEARCH_TERM${NC}"
echo -e "Region:            ${YELLOW}$REGION${NC}"
echo ""
echo -e "EC2 Instances:     ${GREEN}$INSTANCE_COUNT${NC}"
echo -e "Load Balancers:    ${GREEN}$LB_COUNT${NC}"
echo -e "EBS Volumes:       ${GREEN}$VOLUME_COUNT${NC}"
echo -e "Security Groups:   ${GREEN}$SG_COUNT${NC}"
echo -e "VPCs:              ${GREEN}$VPC_COUNT${NC}"
echo -e "S3 Buckets:        ${GREEN}$S3_COUNT${NC}"
echo ""

TOTAL_RESOURCES=$((INSTANCE_COUNT + LB_COUNT + VOLUME_COUNT + SG_COUNT + VPC_COUNT + S3_COUNT))

if [ $TOTAL_RESOURCES -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No resources found matching '$SEARCH_TERM'${NC}"
    echo ""
    echo "Suggestions:"
    echo "  1. Try a different search term or cluster name"
    echo "  2. Check if you're in the correct region"
    echo "  3. Verify AWS credentials have proper permissions"
    echo "  4. Try searching all regions: ./find-cluster-aws-all-regions.sh $SEARCH_TERM"
    exit 1
fi

echo -e "${GREEN}✓ Total resources found: $TOTAL_RESOURCES${NC}"
echo ""

# ============================================================================
# COST ESTIMATE
# ============================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}ESTIMATED COSTS (Approximate)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Very rough cost estimates
INSTANCE_COST=$((INSTANCE_COUNT * 50))  # ~$50/day per instance (varies by type)
VOLUME_COST=$((VOLUME_COUNT * 3))       # ~$3/day per 100GB volume
LB_COST=$((LB_COUNT * 25))              # ~$25/day per LB
TOTAL_DAILY=$((INSTANCE_COST + VOLUME_COST + LB_COST))
TOTAL_MONTHLY=$((TOTAL_DAILY * 30))

echo -e "Daily estimate:    ${YELLOW}~\$${TOTAL_DAILY}${NC}"
echo -e "Monthly estimate:  ${YELLOW}~\$${TOTAL_MONTHLY}${NC}"
echo ""
echo -e "${RED}⚠️  These are rough estimates. Check AWS Cost Explorer for actual costs.${NC}"
echo ""

# ============================================================================
# NEXT STEPS
# ============================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}NEXT STEPS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "To delete these resources, run:"
echo ""
echo -e "  ${GREEN}./cleanup-aws-cluster.sh $SEARCH_TERM $REGION${NC}"
echo ""
echo "Or manually delete with these commands:"
echo ""
echo "# Terminate instances:"
if [ -n "$INSTANCES" ]; then
    INSTANCE_IDS=$(echo "$INSTANCES" | awk '{print $1}' | tr '\n' ' ')
    echo "aws ec2 terminate-instances --region $REGION --instance-ids $INSTANCE_IDS"
fi
echo ""
echo "# Delete load balancers, volumes, security groups, VPC..."
echo "# (See cleanup-aws-cluster.sh for full sequence)"
echo ""
echo -e "${YELLOW}⚠️  WARNING: Deletion is irreversible. Review resources carefully!${NC}"
echo ""

# Save results to file
OUTPUT_FILE="/tmp/aws-cluster-${SEARCH_TERM}-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "AWS Cluster Resources: $SEARCH_TERM"
    echo "Region: $REGION"
    echo "Date: $(date)"
    echo ""
    echo "=== INSTANCES ==="
    echo "$INSTANCES"
    echo ""
    echo "=== LOAD BALANCERS ==="
    echo "$LBS"
    echo ""
    echo "=== VOLUMES ==="
    echo "$VOLUMES"
    echo ""
    echo "=== SECURITY GROUPS ==="
    echo "$SGS"
    echo ""
    echo "=== VPCS ==="
    echo "$VPCS"
    echo ""
    echo "=== S3 BUCKETS ==="
    echo "$S3_BUCKETS"
} > "$OUTPUT_FILE"

echo -e "📄 Results saved to: ${BLUE}$OUTPUT_FILE${NC}"
echo ""



