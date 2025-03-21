//
// Copyright 2021 The Sigstore Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package remote

import (
	"context"
	"errors"
	"os"
	"reflect"
	"testing"

	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/name"
	"github.com/google/go-containerregistry/pkg/v1/remote"
)

func TestOptions(t *testing.T) {
	repo, err := name.NewRepository("gcr.io/projectsigstore")
	if err != nil {
		t.Errorf("NewRepository() = %v", err)
	}

	overrideRepo, err := name.NewRepository("gcr.io/distroless")
	if err != nil {
		t.Errorf("NewRepository() = %v", err)
	}

	otherROpt := []remote.Option{
		remote.WithAuthFromKeychain(authn.DefaultKeychain),
		// TODO(mattmoor): Incorporate user agent.
	}

	moreROpt := []remote.Option{
		remote.WithContext(context.Background()),
	}

	tests := []struct {
		name string
		opts []Option
		want *options
	}{{
		name: "no options",
		want: &options{
			SignatureSuffix:   SignatureTagSuffix,
			AttestationSuffix: AttestationTagSuffix,
			SBOMSuffix:        SBOMTagSuffix,
			TargetRepository:  repo,
			ROpt:              defaultOptions,
		},
	}, {
		name: "signature option",
		opts: []Option{WithSignatureSuffix("pig")},
		want: &options{
			SignatureSuffix:   "pig",
			AttestationSuffix: AttestationTagSuffix,
			SBOMSuffix:        SBOMTagSuffix,
			TargetRepository:  repo,
			ROpt:              defaultOptions,
		},
	}, {
		name: "attestation option",
		opts: []Option{WithAttestationSuffix("pig")},
		want: &options{
			SignatureSuffix:   SignatureTagSuffix,
			AttestationSuffix: "pig",
			SBOMSuffix:        SBOMTagSuffix,
			TargetRepository:  repo,
			ROpt:              defaultOptions,
		},
	}, {
		name: "sbom option",
		opts: []Option{WithSBOMSuffix("pig")},
		want: &options{
			SignatureSuffix:   SignatureTagSuffix,
			AttestationSuffix: AttestationTagSuffix,
			SBOMSuffix:        "pig",
			TargetRepository:  repo,
			ROpt:              defaultOptions,
		},
	}, {
		name: "target repo option",
		opts: []Option{WithTargetRepository(overrideRepo)},
		want: &options{
			SignatureSuffix:   SignatureTagSuffix,
			AttestationSuffix: AttestationTagSuffix,
			SBOMSuffix:        SBOMTagSuffix,
			TargetRepository:  overrideRepo,
			ROpt:              defaultOptions,
		},
	}, {
		name: "remote options option",
		opts: []Option{WithRemoteOptions(otherROpt...)},
		want: &options{
			SignatureSuffix:   SignatureTagSuffix,
			AttestationSuffix: AttestationTagSuffix,
			SBOMSuffix:        SBOMTagSuffix,
			TargetRepository:  repo,
			ROpt:              otherROpt,
		},
	}, {
		name: "more remote options option",
		opts: []Option{WithRemoteOptions(otherROpt...), WithMoreRemoteOptions(moreROpt...)},
		want: &options{
			SignatureSuffix:   SignatureTagSuffix,
			AttestationSuffix: AttestationTagSuffix,
			SBOMSuffix:        SBOMTagSuffix,
			TargetRepository:  repo,
			ROpt:              append(append([]remote.Option{}, otherROpt...), moreROpt...),
		},
	}}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			got := makeOptions(repo, test.opts...)
			test.want.OriginalOptions = test.opts

			if !optionsEqual(got, test.want) {
				t.Errorf("makeOptions() = %#v, wanted %#v", got, test.want)
			}
		})
	}
}

func TestGetEnvTargetRepository(t *testing.T) {
	tests := []struct {
		desc string

		envVal string

		want    name.Repository
		wantErr error
	}{
		{
			desc: "good",

			envVal: "gcr.io/distroless",

			want: name.MustParseReference("gcr.io/distroless").Context(),
		},
		{
			desc: "bad",

			envVal:  "bad$repo",
			wantErr: errors.New("parsing $COSIGN_REPOSITORY: repository can only contain the characters `abcdefghijklmnopqrstuvwxyz0123456789_-./`: bad$repo"),
		},
		{
			desc: "empty",

			envVal: "",
			want:   name.Repository{},
		},
	}

	for _, tc := range tests {
		t.Run(tc.desc, func(t *testing.T) {
			ev := os.Getenv("COSIGN_REPOSITORY")
			defer os.Setenv("COSIGN_REPOSITORY", ev)
			os.Setenv("COSIGN_REPOSITORY", tc.envVal)

			got, err := GetEnvTargetRepository()

			if !errors.Is(err, tc.wantErr) {
				if tc.wantErr == nil || err == nil || tc.wantErr.Error() != err.Error() {
					t.Fatalf("GetEnvTargetRepository() returned error %v, wanted %v", err, tc.wantErr)
				}
				return
			}

			if tc.want != got {
				t.Errorf("GetEnvTargetRepository() returned %#v, wanted %#v", got, tc.want)
			}
		})
	}
}

// this is required due to the fact that reflect.DeepEquals reports
// two different slices of function points, with identical length and
// contents at each position as being different
func optionsEqual(o1, o2 *options) bool {
	if (o1 == nil) != (o2 == nil) {
		return false
	}
	if o1 == nil {
		return true
	}

	if o1.AttestationSuffix != o2.AttestationSuffix {
		return false
	}
	if o1.SignatureSuffix != o2.SignatureSuffix {
		return false
	}
	if o1.SBOMSuffix != o2.SBOMSuffix {
		return false
	}
	if o1.TagPrefix != o2.TagPrefix {
		return false
	}
	if !slicesEqual(o1.ROpt, o2.ROpt) {
		return false
	}
	if !slicesEqual(o1.NameOpts, o2.NameOpts) {
		return false
	}
	if !slicesEqual(o1.OriginalOptions, o2.OriginalOptions) {
		return false
	}
	return true
}

func slicesEqual[T any](o1, o2 []T) bool {
	if len(o1) != len(o2) {
		return false
	}

	for i := range o1 {
		v1 := reflect.ValueOf(o1[i])
		v2 := reflect.ValueOf(o2[i])
		if v1 != v2 {
			return false
		}
	}

	return true
}
